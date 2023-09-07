// SevenNFT Attribute String Library

// SPDX-License-Identifier: MIT
// Copyright (c) 2023, SevenDAO

pragma solidity ^0.8.4;

import "./openzeppelin/utils/ShortStrings.sol";
import "./openzeppelin/utils/Strings.sol";
import "./openzeppelin/utils/structs/EnumerableMap.sol";

library SevenAttributeStrings {

    using ShortStrings for *;
    using EnumerableMap for EnumerableMap.Bytes32ToBytes32Map;

    bytes32 private constant SENTINEL = 0x00000000000000000000000000000000000000000000000000000000000000FF;

    // index is an array of the AttributeStrings
    // each element of index is either a ShortString or the value SENTINEL
    // if index[N] == SENTINEL, then:
    //    overflowIndex[N] = keccak256 hash of string 
    //    overflowStrings[hash] = string
    struct Store {
	bytes32[] index;
	EnumerableMap.Bytes32ToBytes32Map overflowIndex;    // index->hash mapping
	mapping(bytes32 => string) overflowStrings;	    // hash->string mapping
    }

    function length(Store storage strings) internal view returns (uint256) {
	return strings.index.length;
    }

    function clear(Store storage strings) public {
	while(strings.index.length > 0) {
	    strings.index.pop();
	}
	bytes32 index;
	bytes32 hash;
	while(strings.overflowIndex.length() > 0) {
	    (index, hash) = strings.overflowIndex.at(strings.overflowIndex.length()-1);
	    strings.overflowIndex.remove(index);
	    strings.overflowStrings[hash] = "";
	}
    }

    // scan the overflow strings for a matching string value returning 1-based index
    function findOverflow(Store storage strings, bytes32 hash) internal view returns (uint256) {
	bytes32 _index;
	bytes32 _hash;
	for(uint256 i=0; i<strings.overflowIndex.length(); i++) {
	    (_index, _hash) = strings.overflowIndex.at(i);
	    if (hash == _hash) {
		return uint256(_index)+1;
	    }
	}
	return 0;
    }

    // scan the index for a matching bytes32 short string value returning 1-based index
    function findShort(Store storage strings, bytes32 bstr) internal view returns (uint256) {
	for(uint256 i=0; i<strings.index.length; i++) {
	    if (bstr == strings.index[i]) {
		return i+1;
	    }
	}
	return 0;
    }

    // index is 1-based (0 indicates nonexistent string)
    function get(Store storage strings, uint256 index) internal view returns (string memory value) {
	if (index < 1 || index > strings.index.length) {
	    value = "";
	}
	else {
	    --index;
	    bytes32 bstr = strings.index[index];
	    if (bstr == SENTINEL) {
		value = strings.overflowStrings[strings.overflowIndex.get(bytes32(index))];
	    } else {
		value = ShortString.wrap(bstr).toString();
	    }
	}
    }

    // find value string; result is ShortString or keccak hash
    function _find(Store storage strings, string memory value) private view returns (uint256 index, bool short, bytes32 result) {
	// if string is short enough to be a ShortString
	short = bool(bytes(value).length < 32);
	if (short) {
	    result = ShortString.unwrap(ShortStrings.toShortString(value));
	    index = findShort(strings, result);    
	} else {
	    result = keccak256(abi.encodePacked(value));
	    index = findOverflow(strings, result);
	}
    }

    // return index of value; or 0 if not present
    function indexOf(Store storage strings, string memory value) internal view returns (uint256 index) {
	bool short;
	bytes32 hash;
	(index, short, hash) = _find(strings, value); 
    }

    // return true if value is present in strings
    function contains(Store storage strings, string memory value) internal view returns (bool) {
	return bool(indexOf(strings, value) != 0);
    }

    // add a string to the list if it is new, returning 1-based index of the existing or added string
    function set(Store storage strings, string memory value) internal returns (uint256 index) {
	bool short;
	bytes32 result;
	(index, short, result) = _find(strings, value);
	if(index == 0) {
	    if (short) {
		strings.index.push(result);
		index = strings.index.length;
	    } else {
		strings.index.push(SENTINEL);
		index = strings.index.length;
		strings.overflowStrings[result] = value;
		strings.overflowIndex.set(bytes32(index-1), result);
	    }
	}
    }

    // dump string
    function dump(Store storage strings) public view returns (string memory ret) {
	for (uint256 i=0; i<strings.index.length; i++) {
	    ret = string.concat(ret, get(strings, i+1), "\n");
	}
    }
}
