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
        uint256 currentBasefee,
        uint256 previousBasefee,
        uint256 blockNumber
    ) external {
        emit BasefeeSpikeReported(
            msg.sender,
            currentBasefee,
            previousBasefee,
            blockNumber,
            "Basefee surge detected"
        );
    }
}
