// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./node_modules/@openzeppelin/contracts/access/Ownable.sol";

/** 
* @author Xavier BARADA / github: https://github.com/XaViPanDx
* @author Antoine PICOT / github: https://github.com/hehehe84
**/
/**
* @notice Voting.sol Smart Contract allow registered voters to add as musch proposals 
* they want to finally vote for their favorite.
* The Owner will specify the different states of voting status.
**/
contract Voting is Ownable {

    uint128 public winningProposalID;
    uint128 public winningPropId;
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint128 votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    enum  WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    WorkflowStatus public workflowStatus;
    Proposal[] proposalsArray;
    mapping (address => Voter) voters;


    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);


    /**
    * @dev modifier integration to forbid non voters to interact with Smart Contract.
    **/
    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }
    
    /**
    * @dev constructor integration to allow directly Smart Contract deployer to interact with the Dapp.
    **/
    constructor() {
        voters[msg.sender].isRegistered == true;
    }
    
    /**
    * @dev getVoter() and getOneProposals() functions allow voters to get informations about voters or
    * proposals (by voter address and proposal Id).
    **/
    function getVoter(address _addr) external onlyVoters view returns (Voter memory) {
        return voters[_addr];
    }
    
    function getOneProposal(uint128 _id) external onlyVoters view returns (Proposal memory) {
        return proposalsArray[_id];
    }

    /**
    * @notice RegisteringVoters is the fisrt stage of the voting process.
    $ The owner will add the voters address manually in this stage.
    * A voter address can't be added twice.
    **/
    /**
    * @dev addVoter function use the onlyOwner modifier to restrict this action to Owner.
    **/
    function addVoter(address _addr) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voters registration is not open yet');
        require(voters[_addr].isRegistered != true, 'Already registered');
    
        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }
 
    /**
    * @notice ProposalsRegistrationStarted is the second stage of the voting process.
    * Voters will be able to add as musch proposals thez wants.
    **/
    /**
    * @dev gh
    **/
    function addProposal(string calldata _desc) external onlyVoters {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Proposals are not allowed yet');
        require(keccak256(abi.encode(_desc)) != keccak256(abi.encode("")), 'Vous ne pouvez pas ne rien proposer'); // facultatif
        // voir que desc est different des autres

        Proposal memory proposal;
        proposal.description = _desc;
        proposalsArray.push(proposal);
        emit ProposalRegistered(proposalsArray.length-1);
    }

    /**
    * @notice VotingSessionStarted is the third stage of the voting process.
    * Voters will be able to vote for their favorite proposal.
    **/
    /**
    * @dev hj
    **/

    function setVote( uint128 _id) external onlyVoters {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        require(voters[msg.sender].hasVoted != true, 'You have already voted');
        require(_id < proposalsArray.length, 'Proposal not found'); // pas obligé, et pas besoin du >0 car uint

        uint128 _winningProposalId;
        
        for (uint128 p = 0; p < proposalsArray.length; p++) {
           if (proposalsArray[p].voteCount > proposalsArray[_winningProposalId].voteCount) {
               _winningProposalId = p;
          }
       }
       winningPropId = _winningProposalId;

        voters[msg.sender].votedProposalId = _id;
        voters[msg.sender].hasVoted = true;
        proposalsArray[_id].voteCount++;

        emit Voted(msg.sender, _id);
    }
    
    /**
    * @dev States functions witch wll be activated by Owner to orchestrate the vote process.
    * Without activation, nobody will be able to interact with wrong status's functions ans an error 
    * message will be send.
    **/
    function startProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Registering proposals cant be started now');
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        
        Proposal memory proposal;
        proposal.description = "GENESIS";
        proposalsArray.push(proposal);
        
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    function endProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Registering proposals havent started yet');
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, 'Registering proposals phase is not finished');
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    /**
    * @notice VotingSessionEnded is the thirdfourth stage of the voting process.
    * OnlyOwner will be able to reveal the winning proposal Id.
    **/
    /**
    * @dev The winning proposal Id will be directly caught in the setVote function.
    **/
    function tallyVotes() external onlyOwner {
       require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Current status is not voting session ended");
        winningProposalID = winningPropId;
       
       workflowStatus = WorkflowStatus.VotesTallied;
       emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }
}