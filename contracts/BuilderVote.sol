// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BuilderVote {
    address public owner;
    mapping(bytes32 => bool) public hasVoted;
    mapping(string => uint256) public votes;

    constructor() {
        owner = msg.sender;
    }

    function vote(string memory proposal, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 hash = keccak256(abi.encodePacked(proposal, msg.sender));
        require(!hasVoted[hash], "Already voted");

        bytes32 message = prefixed(keccak256(abi.encodePacked(proposal, msg.sender)));
        address signer = ecrecover(message, v, r, s);
        require(signer == msg.sender, "Invalid signature");

        votes[proposal]++;
        hasVoted[hash] = true;
    }

    function getVotes(string memory proposal) public view returns (uint256) {
        return votes[proposal];
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

