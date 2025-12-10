// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ResponseBasefee {
    event BasefeeSpikeReported(
        address indexed reporter,
        uint256 currentBasefee,
        uint256 previousBasefee,
        uint256 blockNumber,
        string reason
    );

    function respondWithBasefeeSpike(
        address reporter,
        uint256 currentBasefee,
        uint256 previousBasefee,
        uint256 blockNumber,
        string calldata reason
    ) external {
        emit BasefeeSpikeReported(
            reporter,
            currentBasefee,
            previousBasefee,
            blockNumber,
            reason
        );
    }
}
