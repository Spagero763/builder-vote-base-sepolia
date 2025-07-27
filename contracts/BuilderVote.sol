/**
 *Submitted for verification at sepolia.basescan.org on 2025-07-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BuilderVote
 * @dev A simple contract for voting on proposals.
 * This contract is designed for off-chain signature and on-chain verification
 * to allow for gas-less voting experiences (where a relayer pays gas).
 */
contract BuilderVote {
    address public owner;

    // proposal => voter address => has voted
    mapping(string => mapping(address => bool)) public hasVoted;
    mapping(string => uint256) public votes;

    event Voted(address indexed voter, string proposal);

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev The core vote function. A user signs a message containing the proposal,
     * and this function verifies the signature before casting the vote.
     * @param proposal The proposal string to vote for.
     * @param v The recovery id of the signature.
     * @param r The r value of the signature.
     * @param s The s value of the signature.
     */
    function vote(string memory proposal, uint8 v, bytes32 r, bytes32 s) external {
        require(bytes(proposal).length > 0, "Proposal cannot be empty");
        require(!hasVoted[proposal][msg.sender], "Already voted on this proposal");

        // Recreate the message hash that was signed on the client
        bytes32 messageHash = getMessageHash(proposal, msg.sender);
        bytes32 prefixedHash = getEthSignedMessageHash(messageHash);
        
        // Recover the address of the signer
        address signer = ecrecover(prefixedHash, v, r, s);
        require(signer != address(0), "Invalid signature: recovery failed");
        
        // Ensure the signer is the same as the person submitting the transaction
        require(signer == msg.sender, "Invalid signature: signer does not match sender");

        votes[proposal]++;
        hasVoted[proposal][msg.sender] = true;
        emit Voted(msg.sender, proposal);
    }

    /**
     * @dev Gets the current vote count for a given proposal.
     */
    function getVotes(string memory proposal) public view returns (uint256) {
        return votes[proposal];
    }

    /**
     * @dev Creates the EIP-191 compliant signed message hash.
     * This is the hash that `ecrecover` will use for verification.
     */
    function getEthSignedMessageHash(bytes32 _hash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
    }

    /**
     * @dev Creates the hash of the message that the user needs to sign.
     */
    function getMessageHash(string memory _proposal, address _voter) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_proposal, _voter));
    }
}
