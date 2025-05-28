// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.7.0 <0.9.0;

contract lottery{
    

    address public manager;
    address payable[] public players;
    address payable public winner;

    constructor(){
        manager = msg.sender;
    }

    function perticipate() public payable {
        require(msg.value == 10 wei,"please pay 1 ether only");
        players.push(payable(msg.sender));
    }
    
   function getBalance() public view returns(uint){
       return address(this).balance;
   }

   function random() internal view returns(uint){
      return uint(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, players.length)));
  }

function pickWinner() public {
    require(msg.sender == manager, "You are not the manager");
    require(players.length >= 3, "Players are less than 3");

    uint r = random();
    uint index = r % players.length;
    winner = players[index];

    winner.transfer(getBalance()); // transfer all ether to winner

    players = new address payable[](0) ; // ✅ proper syntax
    }
}
