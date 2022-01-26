// SPDX-License-Identifier: unlicensed
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//to manage ownership
import "@openzeppelin/contracts/access/Ownable.sol";

//only owner of the token can mint governance token (owner in our case liquidity pool)
contract GovernanceToken is ERC20, Ownable {
    constructor() ERC20("Governance Token", "GTK") Ownable() {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
