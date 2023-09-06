// SevenNFT onchain Attribute child contract

// SPDX-License-Identifier: MIT
// Copyright (c) 2023, SevenDAO

pragma solidity ^0.8.4;

import "@openzeppelin/utils/structs/EnumerableMap.sol";
import "./SevenAttributeStrings.sol";
    
library SevenTransformations {

    using EnumerableMap for EnumerableMap.Bytes32ToUintMap;
    using SevenAttributeStrings for SevenAttributeStrings.Store;

    string constant private NAME_INIT_MISMATCH = "name init mismatch";

    uint8 constant public MATRIX_LEN = 8;
    uint8 constant public SECTORS = 4;

    struct Matrix {
	uint8 count;
	uint8 baseNameId;
	SevenAttributeStrings.Store names;	
	EnumerableMap.Bytes32ToUintMap map;
    }

    // output string-formatted Transformation Matrix 
    struct MatrixStrings {
	uint8 count;
	string baseName;
	string[MATRIX_LEN] names;
	string[MATRIX_LEN][MATRIX_LEN] matrix;
    }

    function _hash(Matrix storage matrix, uint8 i, uint8 j) private view returns (bytes32) {
	return keccak256(abi.encodePacked(get(matrix, i), get(matrix, j)));
    }

    function initialize(Matrix storage matrix, uint8 count, string memory baseName, string[MATRIX_LEN] memory names, string[MATRIX_LEN][MATRIX_LEN] memory grid) public {
	matrix.count = count;
	for(uint8 i=0; i<count; i++) {
	    uint8 index = set(matrix, names[i]);
	    require(index == i, NAME_INIT_MISMATCH);
	}
	matrix.baseNameId = set(matrix, baseName);
	for(uint8 i=0; i<count; i++) {
	    for(uint8 j=0; j<count; j++) {
		string memory node = grid[i][j];	
		if (bytes(node).length > 0) {
		    uint8 nodeId = set(matrix, node);
		    matrix.map.set(_hash(matrix, i, j), nodeId);
		    matrix.map.set(_hash(matrix, j, i), nodeId);
		}
	    }
	}
    }

    function initializeStrings(Matrix storage matrix, MatrixStrings memory init) internal {
	matrix.count = init.count;
	for(uint8 i=0; i<init.count; i++) {
	    uint8 index = set(matrix, init.names[i]);
	    require(index == i, NAME_INIT_MISMATCH);
	}
	matrix.baseNameId = set(matrix, init.baseName);
	for(uint8 i=0; i<init.count; i++) {
	    for(uint8 j=0; j<init.count; j++) {
		string memory node = init.matrix[i][j];	
		if (bytes(node).length > 0) {
		    uint8 nodeId = set(matrix, node);
		    matrix.map.set(_hash(matrix, i, j), nodeId);
		    matrix.map.set(_hash(matrix, j, i), nodeId);
		}
	    }
	}
    }

    // return string value for an AttributeString index
    function get(Matrix storage matrix, uint8 index) internal view returns (string memory) {
	return matrix.names.get(uint256(index+1));
    }

    // set string into names returing uint8 0-based index
    function set(Matrix storage matrix, string memory attributeValue) internal returns (uint8) {
	return uint8(matrix.names.set(attributeValue)-1);
    }

    // dump matrix as string
    function dump(Matrix storage matrix) internal view returns (string memory ret) {
	ret = "{\n";
	ret = string.concat("  \"count\": ", Strings.toString(uint256(matrix.count)), ",\n");
	ret = string.concat(ret, "  \"basename\": \"", get(matrix, matrix.baseNameId), "\",\n");
	ret = string.concat(ret, "  \"names\":\n  [\n");
	for(uint8 i=0; i<matrix.count; i++) {
	    if (i>0) {
		ret=string.concat(ret, ", ");
	    }
	    ret=string.concat(ret, "\"", get(matrix, i), "\"");
	}
	ret=string.concat(ret, "],\n");
	ret=string.concat(ret, "  \"matrix\": [");
	for(uint8 i=0; i<matrix.count; i++) {
	    if (i>0) {
		ret=string.concat(ret, ",\n  [");
	    } else {
		ret=string.concat(ret, "\n  [");
	    }
	    for(uint8 j=0; j<matrix.count; j++) {
		if (j>0) {
		    ret=string.concat(ret, ", ");
		}
		ret=string.concat(ret, "\"", get(matrix, uint8(matrix.map.get(_hash(matrix, i, j)))), "\"");
	    }
	    ret=string.concat("]\n");
	}
	ret=string.concat(ret, "  ]\n}\n");
    } 

    // return an array of the unique strings ordered by frequency of occurrence
    function _countUniqueStrings(uint8[SECTORS] memory inputIds) private pure returns (uint8 count, uint8[SECTORS] memory ret) {
	uint8[SECTORS] memory frequency;

        for (uint8 i=0; i<SECTORS; i++) {
	    for(uint8 j=0; j<SECTORS; j++) {
		if(inputIds[i] == inputIds[j]) {
		    frequency[i]++;
		}
	    }
	}

	for(uint8 f=SECTORS; f>0; f--) {
	    for(uint8 j=0; j<SECTORS; j++) {
		if(frequency[j] == f) {
		    ret[count++] = inputIds[j];
		}
	    }
	}
    }


    // take four AttributeString indices, return an AttributeString index of the result
    function transform(Matrix storage matrix, uint8[SECTORS] memory elements) internal view returns (uint8 result) {
	uint8 count;
	uint8[SECTORS] memory unique;
	(count, unique) = _countUniqueStrings(elements);
	if (count == 1) {
	    // all 4 identical
	    result = uint8(matrix.map.get(_hash(matrix, unique[0], unique[0])));
	} else if (count == 2) {
	    // 2:2 or 3:1
	    result = uint8(matrix.map.get(_hash(matrix, unique[0], unique[1])));
	} else if (count == 3) {
	    // 2:1:1
	    result = unique[0];
	} else if (count == SECTORS) {
	    // 1:1:1:1
	    result = matrix.baseNameId;
	} else {
	    revert("unexpected count");
	}
    }
}
