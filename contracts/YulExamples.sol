// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract YulExamples {
    //       unused bytes                     c                        b    a
    // 0x01 00000000000000 047b37ef4d76c2366f795fb557e3c15e0607b7d8 000014 000a

    //           unused bytes                             d
    // 0x02 000000000000000000000000 057b37eF4D76c2366F795Fb557E3c15E0607B7D8

    // masking use: 0xFFFFFF
    // 0000000000000000000000000000000000000000000000000000000000FFFFFF
    // Where 0x0F hex == 15 decimal == 1111 bits.                   128|64|32|16|8|4|2|1 = 8 bits (Zero indexed) = 1 byte
    // 0xFFFFFF = 1111111111111111 bits

    struct S {
        uint16 a; // 2 bytes,  2 bytes total
        uint24 b; // 3 bytes,  5 bytes total
        address c; // 20 bytes, 25 bytes total + end of slot 0x01
        address d; // 20 bytes, slot 0x02
    }

    // I've noted the storage slots each state is located at.
    // A single slot is 32 bytes :)
    // uint256 boring;              // 0x00
    // S s_struct;                  // 0x01, 0x02
    // S[] public s_array;                 // 0x03
    // mapping(uint256 => S) public s_map; // 0x04

    // slot 0
    uint256 var1 = 256;

    // slot 1
    address var2 = 0x9ACc1d6Aa9b846083E8a497A661853aaE07F0F00;

    // slot 2
    bytes32 var3 =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // slot 3
    uint128 var4 = 1;
    uint128 var5 = 2;

    // slot 4 & 5
    uint128[4] var6 = [0, 1, 2, 3]; // each element is 16 bytes

    // slot 6
    uint256[] var7;

    // slot 7
    mapping(uint256 => uint256) var8;

    // slot 8
    mapping(uint256 => mapping(uint256 => uint256)) var9;

    struct Var10 {
        uint256 subVar1;
        uint256 subVar2;
    }

    constructor() {
        // s_struct = S({
        //     a: 10,
        //     b: 20,
        //     c: 0x047b37Ef4d76C2366F795Fb557e3c15E0607b7d8,
        //     d: 0x057b37eF4D76c2366F795Fb557E3c15E0607B7D8
        // });
        // boring = 42;
        // s_array.push(s_struct);
        // s_map[1] = s_struct;
        // s_map[2] = s_struct;
        // s_map[4] = s_struct;
    }

    function readAndWriteToStorage()
        external
        returns (uint256, uint256, uint256)
    {
        uint256 x;
        uint256 y;
        uint256 z;

        assembly {
            // gets slot of var5
            let slot := var5.slot

            // gets offset of var5
            let offset := var5.offset

            // assigns x and y from solidity to slot and offset
            x := slot
            y := offset
            // stores value 1 in slot 0
            sstore(0, 1)

            // assigns z to the value from slot 0
            z := sload(0)
        }
        return (x, y, z);
    }

    function getValAtSlot0() public view returns (uint x) {
        assembly {
            x := sload(0x00)
        }
    }

    function view_b() public view returns (uint24) {
        assembly {
            // before: 00000000000000 047b37ef4d76c2366f795fb557e3c15e0607b7d8 000014 000a
            //                                                                         ^
            // after:  0000 00000000000000 047b37ef4d76c2366f795fb557e3c15e0607b7d8 000014
            //          ^
            let v := shr(0x10, sload(0x01))

            // If both characters aren't 0, keep the bit (1). Otherwise, set to 0.
            // mask:   0000000000000000000000000000000000000000000000000000000000 FFFFFF
            // v:      000000000000000000047b37ef4d76c2366f795fb557e3c15e0607b7d8 000014
            // result: 0000000000000000000000000000000000000000000000000000000000 000014
            v := and(0xffffff, v)

            // Store in memory bc return uses memory.
            mstore(0x40, v)

            // Return reads left to right.
            // Since our value is far right we can just return 32 bytes from the 64th byte in memory.
            return(0x40, 0x20)
        }
    }

    //          unused bytes                     c                        b    a
    // before: 00000000000000 047b37ef4d76c2366f795fb557e3c15e0607b7d8 000014 000a
    //          unused bytes                     c                        b    a
    // after:  00000000000000 047b37ef4d76c2366f795fb557e3c15e0607b7d8 0001F4 000a
    function set_b(uint24 b) public {
        assembly {
            // Removing the `uint16` from the right.
            // before: 00000000000000 047b37ef4d76c2366f795fb557e3c15e0607b7d8 000014 000a
            //                                                                         ^
            // after:  0000 00000000000000 047b37ef4d76c2366f795fb557e3c15e0607b7d8 000014
            //          ^
            let new_v := shr(0x10, sload(0x01))

            // Create our mask.
            new_v := and(0xffffff, new_v)

            // Input our value into the mask.
            new_v := xor(b, new_v)

            // Add back the removed `a` value bits.
            new_v := shl(0x10, new_v)

            // Replace original 32 bytes' `000014` with `0001F4`.
            new_v := xor(new_v, sload(0x01))

            // Store our new value.
            sstore(0x01, new_v)
        }
    }

    // keccak256(array_slot) + var_slot
    // keccak256(0x03) + 1
    // Remember how `s_struct` takes up 2 slots?
    // The `+ 1` indicates the second slot allocation in S
    // For the bitpacked slot in S we use don't need the add
    // The next element's slot would be `+ 2`
    function get_elementD() external view returns (bytes32) {
        assembly {
            // Store array slot in memory.
            mstore(0x40, 0x03)
            // Keccak does the MLOAD internally so we give the memory location.
            let hash := add(keccak256(0x40, 0x20), 1)
            // Store the return value.
            mstore(0x40, sload(hash))
            // Return `d`.
            return(0x40, 0x20)
        }
    }

    // TODO: return c, not all of slot 0
    function get_elementC() external view returns (bytes32) {
        assembly {
            // Store array slot in memory.
            mstore(0x40, 0x03)
            // Keccak does the MLOAD internally so we give the memory location.
            let hash := keccak256(0x40, 0x20)
            // Store the return value.
            mstore(0x40, sload(hash))
            // Return `c`.
            return(0x40, 0x20)
        }
    }

    // TODO: return .b, not all of slot 0
    // s_map[2].b
    // keccak256(mapping_key . mapping_slot)
    // keccak256(0x02 . 0x04)
    function getMapping2B() public view returns (bytes32) {
        assembly {
            // Store map key (the element we want).
            mstore(0, 0x02)
            // Store map slot location.
            mstore(0x20, 0x04)
            // We want `b` in the first slot 0x00.
            let slot := keccak256(0, 0x40)
            // Store our value for return.
            mstore(0, sload(slot))
            return(0, 0x20)
        }
    }

    // s_map[4].d
    // keccak256(mapping_key . mapping_slot) + i`
    // keccak256(0x02 . 0x04) + 1
    function getMapping4D() external view returns (bytes32) {
        assembly {
            // Store map key (the element we want).
            mstore(0, 0x04)
            // Store map slot location.
            mstore(0x20, 0x04)
            // We want `d` which is 1 slot more.
            let slot := add(keccak256(0, 0x40), 0x01)
            // Store our value for return.
            mstore(0, sload(slot))
            return(0, 0x20)
        }
    }

    // input is the storage slot that we want to read
    function getValInHex(uint256 y) external view returns (bytes32) {
        // since Yul works with hex we want to return in bytes
        bytes32 x;

        assembly {
            // assign value of slot y to x
            x := sload(y)
        }

        return x;
    }

    function getValFromDynamicArray(
        uint256 targetIndex
    ) external view returns (uint256) {
        // get the slot of the dynamic array
        uint256 slot;

        assembly {
            slot := var7.slot
        }

        // get hash of slot for start index
        bytes32 startIndex = keccak256(abi.encode(slot));

        uint256 ans;

        assembly {
            // adds start index and target index to get storage location. Then loads corresponding storage slot
            ans := sload(add(startIndex, targetIndex))
        }

        return ans;
    }

    function getMappedValue(uint256 key) external view returns (uint256) {
        // get the slot of the mapping
        uint256 slot;

        assembly {
            slot := var8.slot
        }

        // hashs the key and uint256 value of slot
        bytes32 location = keccak256(abi.encode(key, slot));

        uint256 ans;

        // loads storage slot of location and returns ans
        assembly {
            ans := sload(location)
        }

        return ans;
    }

    function getMappedValue(
        uint256 key1,
        uint256 key2
    ) external view returns (uint256) {
        // get the slot of the mapping
        uint256 slot;
        assembly {
            slot := var9.slot
        }
        // hashs the key and uint256 value of slot
        bytes32 locationOfParentValue = keccak256(abi.encode(key1, slot));
        // hashs the parent key with the nested key
        bytes32 locationOfNestedValue = keccak256(
            abi.encode(key2, locationOfParentValue)
        );

        uint256 ans;
        // loads storage slot of location and returns ans
        assembly {
            ans := sload(locationOfNestedValue)
        }

        return ans;
    }

    function readVar4AndVar5() external view returns (uint128, uint128) {
        uint128 readVar4;
        uint128 readVar5;

        bytes32 mask = 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;

        assembly {
            let slot3 := sload(3)

            // the and() operation sets var5 to 0x00
            readVar4 := and(slot3, mask)

            // var5.offset = 10 bytes = 16 in decimal, therefore mul(10,8) = 80 bytes = 128 in decimal, therefore shr(128 bits, slot3)
            // we shift var5 to var4's position
            // var5's old position becomes 0x00
            readVar5 := shr(mul(var5.offset, 8), slot3)
        }

        return (readVar4, readVar5);
    }

    function writeVar5(uint256 newVal) external {
        assembly {
            // load slot 3
            let slot3 := sload(3)

            // mask for clearing var5
            let
                mask
            := 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff

            // isolate var4
            let clearedVar5 := and(slot3, mask)
            // 0x0000000000000000000000000000000000000000000000000000000000000001

            // format new value into var5 position
            let shiftedVal := shl(mul(var5.offset, 8), newVal) // newVal = 4
            // 0x0000000000000000000000000000000400000000000000000000000000000000

            // combine new value with isolated var4
            let newSlot3 := or(shiftedVal, clearedVar5)
            // 0x0000000000000000000000000000000400000000000000000000000000000001

            // store new value to slot 3
            sstore(3, newSlot3)
        }
    }

    function getStructValues() external pure returns (uint256, uint256) {
        // initialize struct
        Var10 memory s;
        s.subVar1 = 32;
        s.subVar2 = 64;

        assembly {
            return(0x80, 0xc0)
        }
    }

    function getDynamicArray(
        uint256[] memory arr
    ) external view returns (uint256[] memory) {
        assembly {
            // where array is stored in memory (0x80)
            let location := arr

            // length of array is stored at arr (4)
            let length := mload(arr)

            // gets next available memory location
            let nextMemoryLocation := add(
                add(location, 0x20),
                mul(length, 0x20)
            )

            // stores new value to memory
            mstore(nextMemoryLocation, 4)

            // increment length by 1
            length := add(length, 1)

            // store new length value
            mstore(location, length)

            // update free memory pointer
            mstore(0x40, 0x140)

            return(add(location, 0x20), mul(length, 0x20))
        }
    }
}

contract CallMe {
    uint256 public var1 = 1;
    uint256 public var2 = 2;
    bytes4 selectorA = 0x773d45e0;
    bytes4 selectorB = 0x4df7e3d0;

    function a(
        uint256 _var1,
        uint256 _var2
    ) external payable returns (uint256, uint256) {
        // requires 1 ether was sent to contract
        require(msg.value >= 1 ether);

        // updates var1 & var2
        var1 = _var1;
        var2 = _var2;

        // returns var1 & var2
        return (var1, var2);
    }

    function b() external view returns (uint256, uint256) {
        return (var1, var2);
    }

    function getVars(address _callMe) external view returns (uint256, uint256) {
        assembly {
            // load slot 2 from memory
            let slot2 := sload(2)

            // shift selectorA off
            let funcSelector := shr(32, slot2)

            // store selectorB to memory location 0x80
            mstore(0x00, funcSelector)

            // static call CallMe
            let result := staticcall(gas(), _callMe, 0x1c, 0x20, 0x80, 0xc0)

            // check if call was succesfull, else revert
            if iszero(result) {
                revert(0, 0)
            }

            // return values from memory
            return(0x80, 0xc0)
        }
    }

    function callA(
        address _callMe,
        uint256 _var1,
        uint256 _var2
    ) external payable returns (bytes memory) {
        assembly {
            // load slot 2
            let slot2 := sload(2)

            // isolate selectorA
            let
                mask
            := 0x000000000000000000000000000000000000000000000000000000000ffffffff
            let funcSelector := and(mask, slot2)

            // store function selectorA
            mstore(0x80, funcSelector)

            // copies calldata to memory location 0xa0
            // leaves out function selector and _callMe
            calldatacopy(0xa0, 0x24, sub(calldatasize(), 0x20))

            // call contract
            let result := call(
                gas(),
                _callMe,
                callvalue(),
                0x9c,
                0xe0,
                0x100,
                0x120
            )

            // check if call was succesfull, else revert
            if iszero(result) {
                revert(0, 0)
            }

            // return values from memory
            return(0x100, 0x120)
        }
    }

    function delgatecallA(
        address _callMe,
        uint256 _var1,
        uint256 _var2
    ) external payable returns (bytes memory) {
        assembly {
            // load slot 2
            let slot2 := sload(2)

            // isolate selectorA
            let
                mask
            := 0x000000000000000000000000000000000000000000000000000000000ffffffff
            let funcSelector := and(mask, slot2)

            // store function selectorA
            mstore(0x80, funcSelector)

            // copies calldata to memory location 0xa0
            // leaves out function selector and _callMe
            calldatacopy(0xa0, 0x24, sub(calldatasize(), 0x20))

            // call contract
            let result := delegatecall(gas(), _callMe, 0x9c, 0xe0, 0x100, 0x120)

            // check if call was successful, else revert
            if iszero(result) {
                revert(0, 0)
            }

            // return values from memory
            return(0x100, 0x120)
        }
    }
}
