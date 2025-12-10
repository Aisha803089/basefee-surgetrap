// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/ITrap.sol";

contract BasefeeSurgeTrap is ITrap {
    uint256 private constant SURGE_MULTIPLIER = 2;

    function collect() external view override returns (bytes memory) {
        return abi.encode(block.basefee, block.number);
    }

    function shouldRespond(
        bytes[] calldata data
    ) external pure override returns (bool, bytes memory) {
        if (data.length == 0 || data[0].length == 0) return (false, bytes(""));

        if (data.length < 2 || data[1].length == 0) return (false, bytes(""));

        if (data[0].length < 64 || data[1].length < 64)
            return (false, bytes(""));

        (uint256 basefeeNew, uint256 blockNew) = abi.decode(
            data[0],
            (uint256, uint256)
        );
        (uint256 basefeePrev, uint256 blockPrev) = abi.decode(
            data[1],
            (uint256, uint256)
        );

        if (basefeePrev == 0) return (false, bytes(""));

        bool trigger = (basefeeNew >= basefeePrev * SURGE_MULTIPLIER);

        if (!trigger) return (false, bytes(""));

        bytes memory payload = abi.encode(
            address(0),
            basefeeNew,
            basefeePrev,
            blockNew,
            string("Basefee surge detected")
        );

        return (true, payload);
    }
}
