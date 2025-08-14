// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console} from "forge-std/console.sol";
import "./Market.sol";

/*
  Factory that deploys ERC20 and Market
*/
contract BondingFactory {
    address public owner;
    address public router; // UniswapV2 router address
    mapping(address => address) public tokenToMarket;

    event TokenAndMarketCreated(address indexed token, address indexed market, address indexed creator);

    constructor(address _router) {
        owner = msg.sender;
        router = _router;
    }

    function createToken(string memory name, string memory symbol, uint256 _initialMint)
        external
        returns (
            // uint256 _a,
            // uint256 _b,
            // uint256 _targetEth,
            // uint256 _treasuryFeeBps,
            // address _admin
            address tokenAddr,
            address marketAddr
        )
    {
        ERC20Mintable token = new ERC20Mintable(name, symbol, 0, address(this));
        tokenAddr = address(token);

        Market market = new Market(tokenAddr);
        // router,
        // _a,
        // _b,
        // _initialMint,
        // _targetEth,
        // _treasuryFeeBps,
        // _admin // admin

        marketAddr = address(market);
        token.mint(marketAddr, _initialMint);
        tokenToMarket[tokenAddr] = marketAddr;

        emit TokenAndMarketCreated(tokenAddr, marketAddr, msg.sender);
        return (tokenAddr, marketAddr);
    }

    function setRouter(address _router) external {
        require(msg.sender == owner, "only owner");
        router = _router;
    }
}
