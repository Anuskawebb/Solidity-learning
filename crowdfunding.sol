// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract crowdfunding {

    struct Request {
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address => bool) voters;
    }

    mapping(address => uint) public contributors;
    mapping(uint => Request) public requests;

    uint public numRequests; // corrected from noOfrequests
    address public manager;
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors;

    constructor(uint _target, uint _deadline) {
        target = _target;
        deadline = block.timestamp + _deadline;
        minimumContribution = 100 wei;
        manager = msg.sender;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can run this function");
        _;
    }

    function createRequest(string calldata _description, address payable _recipient, uint _value) public onlyManager {
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }

    function contribution() public payable{
        require(block.timestamp <deadline, "Deadline has passed");
        require(msg.value>=minimumContribution,"Contribution must be atleast 100 wei");
        if(contributors[msg.sender]==0){
          noOfContributors++;
        }

        contributors[msg.sender]+=msg.value;
        raisedAmount += msg.value;
     
    }

    function getContractbalance() public view returns(uint){
        return address(this).balance;
    }
    function refund() public{
        require(block.timestamp>deadline && raisedAmount<target,"you're not eligible for the refund");
        require(contributors[msg.sender]>0,"you're not a contributor");
        payable(msg.sender).transfer(contributors[msg.sender]);
        contributors[msg.sender]=0;
    }

    function voteRequest(uint requestNo) public {
    require(contributors[msg.sender] > 0, "You're not a contributor");
    Request storage thisRequest = requests[requestNo];
    require(thisRequest.voters[msg.sender] == false, "You've already voted");
    thisRequest.voters[msg.sender] = true;
    thisRequest.noOfVoters++;
}

function makePayment(uint requestNo) public onlyManager {
    require(raisedAmount >= target, "Target is not reached");

    Request storage thisRequest = requests[requestNo];
    require(thisRequest.completed == false, "The request has been completed");
    require(thisRequest.noOfVoters > noOfContributors / 2, "Majority does not support the request");

    thisRequest.recipient.transfer(thisRequest.value);
    thisRequest.completed = true;
}
}

 