// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {
    using SafeMath for uint256;

    struct Voter {
        bool registered;
        bool hasVoted;
        uint votedTo;
    }

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    struct Election {
        bool isActive;
        uint startTime;
        uint endTime;
        mapping(uint => Candidate) candidates;
        mapping(address => Voter) voters;
        uint candidateCount;
        uint totalVotes;
    }

    mapping(uint => Election) public elections;
    uint public electionCount;

    event VoterRegistered(address indexed voter);
    event CandidateAdded(uint indexed electionId, uint candidateId, string name);
    event VoteCast(address indexed voter, uint indexed electionId, uint candidateId);
    event ElectionStarted(uint indexed electionId);
    event ElectionEnded(uint indexed electionId, string winnerName);

    modifier onlyDuringVoting(uint electionId) {
        require(block.timestamp >= elections[electionId].startTime, "Voting has not started yet");
        require(block.timestamp <= elections[electionId].endTime, "Voting has ended");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner(), "Only admin can perform this action");
        _;
    }

    function registerVoter(address voter) external onlyAdmin {
        require(!elections[electionCount].voters[voter].registered, "Voter is already registered");
        elections[electionCount].voters[voter].registered = true;
        emit VoterRegistered(voter);
    }

    function addCandidate(string calldata name) external onlyAdmin {
        require(!elections[electionCount].isActive, "Cannot add candidates to an ongoing election");

        Election storage election = elections[electionCount];
        election.candidateCount = election.candidateCount.add(1);
        election.candidates[election.candidateCount] = Candidate(election.candidateCount, name, 0);
        
        emit CandidateAdded(electionCount, election.candidateCount, name);
    }

    function startElection(uint startTime, uint endTime) external onlyAdmin {
        require(!elections[electionCount].isActive, "Election is already active");
        require(startTime < endTime, "Start time must be less than end time");

        Election storage election = elections[electionCount];
        election.isActive = true;
        election.startTime = startTime;
        election.endTime = endTime;

        emit ElectionStarted(electionCount);
    }

    function endElection() external onlyAdmin {
        require(elections[electionCount].isActive, "No active election to end");
        elections[electionCount].isActive = false;

        // Determine the winner
        uint winnerId;
        uint highestVotes = 0;
        for (uint i = 1; i <= elections[electionCount].candidateCount; i++) {
            if (elections[electionCount].candidates[i].voteCount > highestVotes) {
                highestVotes = elections[electionCount].candidates[i].voteCount;
                winnerId = i;
            }
        }

        string memory winnerName = elections[electionCount].candidates[winnerId].name;
        emit ElectionEnded(electionCount, winnerName);
    }

    function vote(uint candidateId) external onlyDuringVoting(electionCount) {
        require(elections[electionCount].voters[msg.sender].registered, "You must be a registered voter");
        require(!elections[electionCount].voters[msg.sender].hasVoted, "You have already voted");
        require(candidateId > 0 && candidateId <= elections[electionCount].candidateCount, "Invalid candidate ID");

        elections[electionCount].voters[msg.sender].hasVoted = true;
        elections[electionCount].candidates[candidateId].voteCount = elections[electionCount].candidates[candidateId].voteCount.add(1);
        elections[electionCount].totalVotes = elections[electionCount].totalVotes.add(1);

        emit VoteCast(msg.sender, electionCount, candidateId);
    }

    function createElection() external onlyAdmin {
        electionCount = electionCount.add(1);
    }
}