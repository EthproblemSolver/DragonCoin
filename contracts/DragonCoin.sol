//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DragonCoin is ERC20PresetMinterPauser, ERC20Capped, Ownable {
    using SafeMath for uint256;
    // Addresses for marketing and team wallets
    address public marketingWallet = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
    address public teamWallet = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2; // Add your team wallet address here

    // Total redistribution and LP balances
    uint256 private _totalRedistributionBalance;
    uint256 public lpBalance;
    uint256 public redistributionBalance;

    uint16 public buyTaxRate = 50; // 5% on buy
    uint16 public sellTaxRate = 50; // 5% on sell
    uint16 public transferTaxRate = 50; // 5% on transfer
    uint16 public maximumTaxPercentage = 100; // 10%

    // Pair address for identifying buy, sell, or transfer
    address private _pair;

    // Flags to enable/disable taxes
    bool public taxesEnabled = true; // Flag to enable/disable taxes

    //events
    event EtherWithdrawn(address indexed to, uint256 amount);
    event EtherDeposited(address indexed from, uint256 amount);
    event TaxRatesUpdated(
        uint16 indexed newBuyTaxRate,
        uint16 indexed newSellTaxRate,
        uint16 indexed newTransferTaxRate
    );
    event TaxesUpdated(
        uint16 marketing,
        uint16 burn,
        uint16 team,
        uint16 redistribution,
        uint16 lp
    );
    event LpWithdrawn(uint256 indexed amount);
    event TaxesEnabled(string message);
    event TaxesDisabled(string message);
    event PairAddressUpdated(address indexed newPair);

    // Struct to hold tax percentages
    struct Taxes {
        uint16 marketing;
        uint16 burn;
        uint16 team;
        uint16 redistribution;
        uint16 lp;
    }

    Taxes public transferTaxes = Taxes(300, 100, 300, 200, 100); // Initialize with default values (3%, 1%, 3%, 2%, 1%)

    // Mapping to exclude addresses from taxes
    mapping(address => bool) private _isExcludedFromTaxes;

    // Mapping to detect bot addresses
    mapping(address => bool) private _isBot;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 supply,
        address beneficiary
    )
        ERC20PresetMinterPauser(tokenName, tokenSymbol)
        ERC20Capped(SafeMath.mul(supply, 1 ether))
    {
        // _isExcludedFromTaxes[beneficiary] = true;
        _mint(beneficiary, SafeMath.mul(supply, 1 ether));
        // _mint(beneficiary, supply);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20PresetMinterPauser) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override(ERC20) {
        // Check if the sender is identified as a bot
        if (_isBot[sender]) {
            revert("You are identified as a bot");
        }

        // Check if taxes are enabled
        if (taxesEnabled) {
            // Calculate taxes
            uint256 taxAmount = 0;

            // Determine the type of transfer (buy, sell, or regular transfer)
            if (sender == _pair) {
                // Buy tax
                taxAmount = amount.mul(buyTaxRate).div(1000);
            } else if (recipient == _pair) {
                // Sell tax
                taxAmount = amount.mul(sellTaxRate).div(1000);
            } else {
                // Transfer tax
                taxAmount = amount.mul(transferTaxRate).div(1000);
            }

            // Exclude certain addresses from taxes
            if (
                !_isExcludedFromTaxes[sender] &&
                !_isExcludedFromTaxes[recipient]
            ) {
                // Deduct tax amount from the transferred amount
                uint256 netAmount = amount.sub(taxAmount);

                // Update redistribution and LP balances
                redistributionBalance = redistributionBalance.add(
                    taxAmount.mul(transferTaxes.redistribution).div(1000)
                );
                lpBalance = lpBalance.add(
                    taxAmount.mul(transferTaxes.lp).div(1000)
                );

                // Distribute taxes
                super._transfer(
                    sender,
                    teamWallet,
                    taxAmount.mul(transferTaxes.team).div(1000)
                );
                super._transfer(
                    sender,
                    marketingWallet,
                    taxAmount.mul(transferTaxes.marketing).div(1000)
                );
                super._transfer(
                    sender,
                    address(this),
                    SafeMath.add(
                        taxAmount.mul(transferTaxes.lp).div(1000),
                        taxAmount.mul(transferTaxes.redistribution).div(1000)
                    )
                );
                _burn(sender, taxAmount.mul(transferTaxes.burn).div(1000));

                // Call parent implementation with the net amount after taxes
                super._transfer(sender, recipient, netAmount);
            } else {
                // Call parent implementation with the original amount
                super._transfer(sender, recipient, amount);
            }
        } else {
            // If taxes are disabled, simply transfer the amount
            super._transfer(sender, recipient, amount);
        }
    }

    function _mint(address account, uint256 amount)
        internal
        virtual
        override(ERC20, ERC20Capped)
    {
        require(totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }

    /**
     * @dev Excludes an address from taxes. Only callable by the owner.
     * @param account The address to be excluded from taxes.
     * @notice Once excluded, the specified address will not incur any taxes on transfers.
     */
    function excludeFromTaxes(address account) public onlyOwner {
        _isExcludedFromTaxes[account] = true;
    }

    /**
     * @dev Includes an address in taxes. Only callable by the owner.
     * @param account The address to be included in taxes.
     * @notice Once included, the specified address will be subject to taxes on transfers.
     */
    function includeInTaxes(address account) public onlyOwner {
        _isExcludedFromTaxes[account] = false;
    }

    /**
     * @dev Checks if an address is excluded from taxes.
     * @param account The address to check for exclusion from taxes.
     * @return Whether the address is excluded from taxes or not.
     */
    function isExcludedFromTaxes(address account) public view returns (bool) {
        return _isExcludedFromTaxes[account];
    }

    /**
     * @dev Sets the bot status of an address. Only callable by the owner.
     * @param account The address for which the bot status is to be set.
     * @param state The new bot status to be set (true for bot, false for non-bot).
     * @notice Bots may have restricted functionality depending on your implementation.
     */

    function setBot(address account, bool state) external onlyOwner {
        require(_isBot[account] != state, "Value already set");
        _isBot[account] = state;
    }

    /**
     * @dev Sets the bot status for multiple addresses. Only callable by the owner.
     * @param accounts An array of addresses for which the bot status is to be set.
     * @param state The new bot status to be set (true for bot, false for non-bot).
     * @notice Bots may have restricted functionality depending on your implementation.
     */
    function bulkSetBot(address[] memory accounts, bool state)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isBot[accounts[i]] = state;
        }
    }

    /**
     * @dev Checks if an address is identified as a bot.
     * @param account The address to check for bot status.
     * @return Whether the address is identified as a bot or not.
     * @notice Bot status may affect certain functionalities based on your implementation.
     */

    function isBot(address account) public view returns (bool) {
        return _isBot[account];
    }

    /**
     * @dev Enables taxes. Only callable by the owner.
     * @notice Once enabled, taxes will be applied on transfers according to configured rates.
     */
    function enableTaxes() external onlyOwner {
        taxesEnabled = true;
        emit TaxesEnabled("Taxes are now enabled.");
    }

    /**
     * @dev Disables taxes. Only callable by the owner.
     * @notice Once disabled, taxes will not be applied on transfers.
     */
    function disableTaxes() external onlyOwner {
        taxesEnabled = false;
        emit TaxesDisabled("Taxes are now disabled.");
    }

    /**
     * @dev Sets the pair address for the contract. Only callable by the owner.
     * @param newPair The new pair address to be set.
     * @notice The pair address is typically associated with a decentralized exchange (DEX).
     */
    function setPairAddress(address newPair) external onlyOwner {
        require(
            newPair != address(0),
            "DragonCoin: Pair address cannot be zero address"
        );
        _pair = newPair;
        emit PairAddressUpdated(newPair);
    }

    /**
     * @dev Performs an airdrop to multiple recipients.
     * @param recipients An array of addresses to receive the airdrop.
     * @param amounts An array of amounts to be airdropped to each recipient.
     * @notice The amounts array must have the same length as the recipients array.
     */
    function airdrop(address[] memory recipients, uint256[] memory amounts)
        external
        onlyOwner
    {
        require(
            recipients.length == amounts.length,
            "Mismatched arrays length"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 amount = amounts[i];

            require(amount > 0, "Airdrop amount must be greater than 0");
            require(
                amount <= redistributionBalance,
                "Insufficient redistribution balance"
            );

            // Perform airdrop
            _transfer(address(this), recipients[i], amount);

            // Update redistribution balance
            redistributionBalance = redistributionBalance.sub(amount);
        }
    }

    /**
     * @dev Function to withdraw LP tokens. Only callable by the owner.
     * @param amount The amount of LP tokens to be withdrawn.
     * @notice LP tokens are typically associated with liquidity provision on decentralized exchanges.
     */
    function withdrawLp(uint256 amount) external onlyOwner {
        require(amount <= lpBalance, "Insufficient LP balance");
        lpBalance = lpBalance.sub(amount);
        _transfer(address(this), owner(), amount);
        emit LpWithdrawn(amount);
    }

    /**
     * @dev Function to withdraw Ether to a specific address. Only callable by the owner.
     * @param to The address to which the Ether should be withdrawn.
     * @param amount The amount of Ether to be withdrawn.
     */
    function withdrawEther(address to, uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        payable(to).transfer(amount);

        // Emit an event to log the withdrawal of Ether.
        emit EtherWithdrawn(to, amount);
    }

    /**
     * @dev Function to update tax rates. Only callable by the owner.
     * @param newBuyTaxRate The new tax rate for buys.
     * @param newSellTaxRate The new tax rate for sells.
     * @param newTransferTaxRate The new tax rate for transfers.
     * @notice Tax rates are in basis points (1% = 100 basis points).
     */

    function updateTaxRates(
        uint16 newBuyTaxRate,
        uint16 newSellTaxRate,
        uint16 newTransferTaxRate
    ) external onlyOwner {
        require(
            newBuyTaxRate <= maximumTaxPercentage &&
                newSellTaxRate <= maximumTaxPercentage &&
                newTransferTaxRate <= maximumTaxPercentage,
            "Invalid tax rate"
        );
        buyTaxRate = newBuyTaxRate;
        sellTaxRate = newSellTaxRate;
        transferTaxRate = newTransferTaxRate;

        emit TaxRatesUpdated(newBuyTaxRate, newSellTaxRate, newTransferTaxRate);
    }

    /**
     * @dev Function to update taxes percentages. Only callable by the owner.
     * @param marketing The new percentage for marketing.
     * @param burn The new percentage for burning.
     * @param team The new percentage for the team.
     * @param redistribution The new percentage for redistribution.
     * @param lp The new percentage for LP tokens.
     * @notice The sum of percentages should not exceed 1000 (100%).
     */
    function updateTaxes(
        uint16 marketing,
        uint16 burn,
        uint16 team,
        uint16 redistribution,
        uint16 lp
    ) external onlyOwner {
        require(
            marketing + burn + team + redistribution + lp <= 1000,
            "Total taxes cannot exceed 100%"
        );
        transferTaxes = Taxes(marketing, burn, team, redistribution, lp);

        emit TaxesUpdated(marketing, burn, team, redistribution, lp);
    }

    receive() external payable {
        emit EtherDeposited(msg.sender, msg.value);
    }
}
