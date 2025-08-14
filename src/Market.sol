// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console} from "forge-std/console.sol";
import {ERC20Mintable} from "./ERC20Mintable.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Market is ReentrancyGuard {
    // --- Config ---
    uint256 public constant SCALE = 1e18;
    uint256 public treasuryFeeBps = 100;
    address public treasury;
    uint256 public virtualEth = 30 ether;
    uint256 public tokensAvailable = 1073000191 ether;
    uint256 public totalSupply = 1000000000 ether;
    uint256 public soldTokens;
    uint256 public actualEth;
    uint256 public treasuryAccrued;

    mapping(address => uint256) public balanceOf;

    address public token;

    // --- Events ---
    event Bought(address indexed buyer, uint256 ethIn, uint256 fee, uint256 tokensOut);
    event Sold(address indexed seller, uint256 tokensIn, uint256 fee, uint256 ethOut);
    event TreasuryWithdrawn(address indexed to, uint256 amount);
    event ParamsUpdated(uint256 virtualEth, uint256 tokensAvailable, uint256 feeBps);

    constructor(
        // uint256 _virtualEth,
        // uint256 _tokensAvailable,
        // uint256 _totalSupply,
        // address _treasury,
        // uint256 _feeBps
        address _token
    ) {
        treasury = msg.sender;
        token = _token;
        // require(_treasury != address(0), "treasury=0");
        // require(_feeBps <= 10_000, "fee > 100%");
        // virtualEth = _virtualEth;
        // tokensAvailable = _tokensAvailable;
        // totalSupply = _totalSupply;
        // treasury = _treasury;
        // treasuryFeeBps = _feeBps;
        // emit ParamsUpdated(virtualEth, tokensAvailable, treasuryFeeBps);
    }

    // ---------- View math (quotes) ----------

    function calculateTokensBought(uint256 ethInWei) public view returns (uint256) {
        if (ethInWei == 0) return 0;
        uint256 vs = virtualEth;
        uint256 vt = tokensAvailable;
        uint256 k = vs * vt;
        uint256 newVs = vs + ethInWei;
        uint256 newVt = k / newVs;
        uint256 deltaTokens = vt - newVt;

        return deltaTokens;
    }

    function calculateEthPayout(uint256 tokensInUnits) public view returns (uint256) {
        if (tokensInUnits == 0) return 0;
        uint256 vs = virtualEth;
        uint256 vt = tokensAvailable;
        uint256 k = vs * vt;
        uint256 newVt = vt + tokensInUnits;
        uint256 newVs = k / newVt;
        uint256 deltaEth = vs - newVs;

        return deltaEth;
    }

    // ---------- Public buy / sell ----------

    function buy() public payable nonReentrant returns (uint256 tokensOut) {
        require(msg.value > 0, "zero ETH");

        uint256 fee = (msg.value * treasuryFeeBps) / 10_000;
        uint256 net = msg.value - fee;
        uint256 tokensToMint = calculateTokensBought(net);

        require(tokensToMint > 0, "zero tokens out");
        require(tokensToMint <= tokensAvailable, "not enough tokens left");

        virtualEth = virtualEth + net;
        tokensAvailable = tokensAvailable - tokensToMint;
        soldTokens += tokensToMint;
        actualEth += net;
        treasuryAccrued += fee;
        balanceOf[msg.sender] += tokensToMint;

        ERC20Mintable(token).transfer(msg.sender, tokensToMint);
        emit Bought(msg.sender, msg.value, fee, tokensToMint);

        return tokensToMint;
    }

    receive() external payable {
        buy();
    }

    function sell(uint256 tokenAmount) external nonReentrant returns (uint256 ethOut) {
        require(tokenAmount > 0, "zero");
        require(balanceOf[msg.sender] >= tokenAmount, "insufficient balance");
        require(tokenAmount <= soldTokens, "burn > sold");

        // Quote ETH returned BEFORE fees
        uint256 returned = calculateEthPayout(tokenAmount);
        require(returned > 0, "zero ETH out");
        require(address(this).balance >= returned, "insufficient ETH liquidity");

        uint256 fee = (returned * treasuryFeeBps) / 10_000;
        uint256 net = returned - fee;

        virtualEth = virtualEth - returned;
        tokensAvailable = tokensAvailable + tokenAmount;
        soldTokens -= tokenAmount;
        actualEth -= net;
        treasuryAccrued += fee;
        balanceOf[msg.sender] -= tokenAmount;

        ERC20Mintable(token).transferFrom(msg.sender, address(this), tokenAmount);

        (bool ok,) = msg.sender.call{value: net}("");
        require(ok, "ETH send failed");

        emit Sold(msg.sender, tokenAmount, fee, net);
        return net;
    }

    // ---------- Admin ----------

    function setFeeBps(uint256 newBps) external {
        require(msg.sender == treasury, "only treasury");
        require(newBps <= 10_000, "fee > 100%");
        treasuryFeeBps = newBps;
        emit ParamsUpdated(virtualEth, tokensAvailable, treasuryFeeBps);
    }

    function withdrawTreasury(address to, uint256 amount) external nonReentrant {
        require(msg.sender == treasury, "only treasury");
        require(to != address(0), "to=0");
        require(amount <= treasuryAccrued, "exceeds accrued");

        treasuryAccrued -= amount;
        (bool ok,) = to.call{value: amount}("");
        require(ok, "withdraw failed");
        emit TreasuryWithdrawn(to, amount);
    }

    // --- Helpers for tests ---

    function invariantK() external view returns (uint256) {
        return virtualEth * tokensAvailable;
    }

    function spotPrice() external view returns (uint256) {
        if (tokensAvailable == 0) return type(uint256).max;
        return (virtualEth * SCALE) / tokensAvailable;
    }
}
