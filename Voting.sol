//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.18;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable{

    // EVENTS
        event VoterRegistered(address voterAddress); 
        event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
        event ProposalRegistered(uint proposalId);
        event Voted (address voter, uint proposalId);

    // PARAMETERS
        // Voter
        struct Voter {
            bool isRegistered;
            bool hasVoted;
            uint[] votedProposalId;
        }

        // Generate Whitelist
        mapping (address => Voter) whitelist;

        struct Proposal {
            string description;
            uint16 voteCount;
        }

        Proposal[] public proposals;
        string[] winnerProposal;

        enum WorkflowStatus {
            RegisteringVoters,
            ProposalsRegistrationStarted,
            ProposalsRegistrationEnded,
            VotingSessionStarted,
            VotingSessionEnded,
            VotesTallied
        }

        WorkflowStatus session = WorkflowStatus.RegisteringVoters;
        
        constructor () {
            authorize(msg.sender);
        }

    // GENERAL

        // If le Voter is registered by the Admin
        modifier isWhiteListed (address _addr) {
            require(whitelist[_addr].isRegistered, "Address is not registered");
            _;
        }

        // Return the complete list of proposals
        function getProposalsList () public view isWhiteListed(msg.sender) returns (string[] memory) {
            string[] memory list = new string[](proposals.length);
            for (uint i=0; i<proposals.length; i++){
                list[i] = string(abi.encodePacked(i, ": ", proposals[i].description));
            }
            return list;
        }

        // Find and return the biggest voting score to compare it to the others and find ex aequo
        function findTheBiggestProposal() view internal returns (uint){
            require (proposals.length > 0,
                     "Any proposal, can't count !");
            uint max;
            for (uint i=0; i < proposals.length; i++) {
                if (proposals[i].voteCount > max){
                    max = proposals[i].voteCount;
                }
            }
            return max;
        }

        // Return a strings array of best proposals
        function getWinner () public isWhiteListed(msg.sender) returns (string[] memory) {
            require (session == WorkflowStatus.VotesTallied,
                     "Not time to votes taillying !");

            uint max = findTheBiggestProposal();

            for (uint i=0; i < proposals.length; i++) {
                if (proposals[i].voteCount == max){
                    winnerProposal.push(proposals[i].description);
                }
            }
            return winnerProposal;
        }

        // Return the Session State in string
        function getStateSession () public view isWhiteListed(msg.sender) returns (string memory) {
            string memory result;
            if (session == WorkflowStatus.RegisteringVoters){
                result = "RegisteringVoters";
            }
            else if (session == WorkflowStatus.ProposalsRegistrationStarted){
                result = "ProposalsRegistrationStarted";
            }
            else if (session == WorkflowStatus.ProposalsRegistrationEnded){
                result = "ProposalsRegistrationEnded";
            }
            else if (session == WorkflowStatus.VotingSessionStarted){
                result = "VotingSessionStarted";
            }
            else if (session == WorkflowStatus.VotingSessionEnded){
                result = "VotingSessionEnded";
            }
            else if (session == WorkflowStatus.VotesTallied){
                result = "VotesTallied";
            }
            return result;
        }


    // VOTERS

        // Allow registered voter to do proposals
        function proposalsRegisteration(string memory _description)
            public
            isWhiteListed(msg.sender)
        {
            require(session == WorkflowStatus.ProposalsRegistrationStarted,
                    "Not time of proposals registration !");
            require(bytes(_description).length > 0,
                    "Description can't be empty.");

            whitelist[msg.sender].votedProposalId.push(proposals.length);
            proposals.push(Proposal(_description, 0));
            emit ProposalRegistered(proposals.length-1);
        }

        // Allow voters to vote 
        function proposalsVoting(uint _votedProposalId)
            public
            isWhiteListed(msg.sender)
        {
            require(session == WorkflowStatus.VotingSessionStarted,
                    "Not voting time !");
            require(!whitelist[msg.sender].hasVoted,
                    "You voted already !");
            require(_votedProposalId < proposals.length,
                    "Proposal inexistant !");
            proposals[_votedProposalId].voteCount ++;
            whitelist[msg.sender].hasVoted = true;
            emit Voted(msg.sender, _votedProposalId);
        }


// ADMINISTRATION

    // Generate access Voter by adding into whitelist
    function authorize (address _address)
        public
        onlyOwner
    {
        require(session == WorkflowStatus.RegisteringVoters,
                "End of voter registration !");
        Voter memory newVoter;
        newVoter.isRegistered = true;
        whitelist[_address]  = newVoter;
        emit VoterRegistered(_address); 
    }

    // Start the proposal Time
    function startProposalSession ()
        public
        onlyOwner
    {
        require(session == WorkflowStatus.RegisteringVoters,
                "You must be on Voters Registering before start a Proposals Recording Session !");
        
        WorkflowStatus previousSession = session;
        session = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(previousSession, session);
    }

    // Close the proposal Time
    function endProposalSession ()
        public
        onlyOwner
    {
        require(session == WorkflowStatus.ProposalsRegistrationStarted,
                "You must be started a Proposals Recording Session before stop it !");
        WorkflowStatus previousSession = session;
        session = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(previousSession, session);
    }

    // Start the Voting Time
    function startVotingSession ()
        public
        onlyOwner
    {
        require(session == WorkflowStatus.ProposalsRegistrationEnded,
                "You must be started a Proposals Recording Session before stop it !");
        WorkflowStatus previousSession = session;
        session = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(previousSession, session);
    }

    // Close the Voting Time
    function endVotingSession ()
        public
        onlyOwner
    {
        require(session == WorkflowStatus.VotingSessionStarted,
                "You must be started a Proposals Recording Session before stop it !");
        WorkflowStatus previousSession = session;
        session = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(previousSession, session);
    }

    // Start the tallying Time
    function votesTallying()
        public
        onlyOwner
    {
        require(session == WorkflowStatus.VotingSessionEnded,
                "You must be started a Proposals Recording Session before stop it !");
        WorkflowStatus previousSession = session;
        session = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(previousSession, session);
    }
}