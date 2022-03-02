// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

// import "./Owner.sol";

contract CoinFlip {

    address private owner;
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    // modifier to check if caller is owner
    modifier isOwner {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender; 
        emit OwnerSet(address(0), owner);
    }

    // To avoid multiple mappings using a structure instead to store all the values for every user
    struct User {
        uint balance;           // Current balance
        uint betAmount;         // Betted amount for the ongoing bet 
        bool betStatus;         // True if betted, false otherwise
        uint betChoice;         // 0(Head) or 1(Tail)
        bool prevUser;          // False if its a new user, true otherwise
    }

    event Winner(address winnerAddress, uint winAmount);
    // Create an array to store the participants
    address[] usersBetted;
    // Mapping to store structure of every user
    mapping(address => User) public users;

    // Utility function to place bet 
    function _placeBet(uint _betChoice, uint _betAmount) public {

        // If it is a new user, reward them 100 points free to start
        if(users[msg.sender].prevUser == false) {
             users[msg.sender].balance = 100;
             users[msg.sender].prevUser = true;
        }
       
        // Betted amount must be less than equal to the user's balance
        require(_betAmount <= users[msg.sender].balance, "Oops! Low balance :(");
        // If the user have an already ongoing bet, restrict them to place another one
        require(users[msg.sender].betStatus == false, "You already have an ongoing bet :|");
        // Set user's values
        users[msg.sender].betAmount = _betAmount;
        users[msg.sender].balance -= _betAmount;
        users[msg.sender].betStatus = true;
        users[msg.sender].betChoice = _betChoice;
        usersBetted.push(msg.sender);
    }

    function _rewardBets() public isOwner {
        uint256 winChoice = uint256(vrf()) % 2;
        // Iterate over the array of participants and evaluate their bets
        for(uint i = 0; i < usersBetted.length; ++i) {
            _evaluateBets(usersBetted[i], winChoice);
        }
        delete usersBetted;
    }

    function _evaluateBets(address _userAddress, uint _winChoice) internal {
        // require(users[_userAddress].betStatus == true, "You have not placed any bet yet!");
        
        // If users bet turned out to be a win
        if(users[_userAddress].betChoice == _winChoice) {
            users[_userAddress].balance += (2 * users[_userAddress].betAmount);
            emit Winner(_userAddress, (2 * users[_userAddress].betAmount));
        }
        // Set bet status to false again
        users[_userAddress].betStatus = false;
    }
    
    // Function to generate random number (Harmony VRF)
    function vrf() private view returns (bytes32 result) {
        uint[1] memory bn;
        bn[0] = block.number;
        assembly {
            let memPtr := mload(0x40)
            if iszero(staticcall(not(0), 0xff, bn, 0x20, memPtr, 0x20)) {
                invalid()
            }
            result := mload(memPtr)
        }
    }

}
