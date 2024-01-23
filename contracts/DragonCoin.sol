//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DragonCoin is ERC20, ERC20Capped, Ownable {
    // Addresses
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address private deployerWallet = 0xB6216226Ed1b188f517D0Ec47339163AD7cf9D22;
    address private stakingWallet = 0xbF003d1988b6EE92cFaDDe09bA43E916B76a3A3C;
    address private cexWallet = 0xF2556F64B17f72C8A2E80E1caD80eD6D4EeA7849;
    address private lpWallet = 0xB6216226Ed1b188f517D0Ec47339163AD7cf9D22;
    address private lpWalletOne = 0x5023ec088779AFd7569508F86DBDaDd839E8E02a;
    address private p2eWalletOne = 0x1C8cC019dEAEf654Aeb3c8fb948A130aE2EacB22;
    address private p2eWalletTwo = 0xdF51D96B5aB16c753D34c278E7E6185B1eD4E21C;
    address private p2eWalletThree = 0x612f209901Fb0d5e3A0525b3b3d5F921288F56cE;
    address private marketingWallet = 0x2C1bd5DF1F8F9C829f8Bbab0F7576ECEf12f65E9;
    address private marketingWalletOne = 0xC66fe47981a8E65bFb3f18741b9742B00A76bCCC;
    address private marketingWalletTwo = 0xd96541330657Fee4f27268577827320Feb20ebaE;
    address private marketingWalletThree = 0xd17360C901faF0Fa9B671d219a60793073d283D1;
    address private marketingWalletFour = 0xd0F1EA13970ECb65596f76B5a77870C870d66D00;
    address private marketingWalletFive = 0xaaD141D497366BD299dcf98fC33bd65d544D2D5c;
    address private marketingWalletSix = 0x3111F6930d768fCc2f336e82eB5D22ED281bD2Ee;
    address private marketingWalletSev = 0x397123D20fBF39545F2E897D18af928859009859;
    address private marketingWalletEig = 0x14444FbF063dF1456AB813d4b9588F4efC9848cA;
    address private marketingWalletNine = 0xC89d320AfdC0B3305617268890c9E45b26404E74;
    address private marketingWalletTen = 0xAb3DaF14BD077f34ca0746AC99ED1CF720503D85;
    address private redistributionWallet = 0x25fF47A614e6D0BE79A5d61691E6eadD4a57Ed21;
    
    address public _pair;

    // Balances
    uint256 public lpBalance;
    uint256 public redistributionBalance;

    // Tax Rates
    uint16 public buyTaxRate = 50; // 5% on buy
    uint16 public sellTaxRate = 50; // 5% on sell
    uint16 public transferTaxRate = 50; // 5% on transfer
    uint16 public maximumTaxPercentage = 100; // 10%

    // Flags
    bool public taxesEnabled; // Flag to enable/disable taxes
    bool private pairAddressSet = false;

    // Struct to hold tax percentages
    struct Taxes {
        uint16 marketing;
        uint16 burn;
        uint16 team;
        uint16 redistribution;
        uint16 lp;
    }

    // Events
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
    event TaxesEnabled(string message);
    event TaxesDisabled(string message);
    event PairAddressUpdated(address indexed newPair);

    // Struct instance to hold tax percentages
    Taxes public transferTaxes = Taxes(300, 100, 300, 200, 100); // Initialize with default values (3%, 1%, 3%, 2%, 1%)

    // Mapping to exclude addresses from taxes
    mapping(address => bool) private _isExcludedFromTaxes;

    // Mapping to detect bot addresses
    mapping(address => bool) private _isBot;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 supply
    ) ERC20(tokenName, tokenSymbol) ERC20Capped(supply * 1 ether) {
        // Mint 80% of the tokens to LP/DEPLOYER address
        uint256 lpTokens = (supply * 1 ether * 80) / 100;
        _mint(deployerWallet, lpTokens);

        // Mint 5% of the tokens to STAKING address
        uint256 stakingTokens = (supply * 1 ether * 5) / 100;
        _mint(stakingWallet, stakingTokens);

        // Mint 4% of the tokens to CEX address
        uint256 cexTokens = (supply * 1 ether * 4) / 100;
        _mint(cexWallet, cexTokens);

        // Mint 6% of the tokens to P2E address
        uint256 p2eTokens = (supply * 1 ether * 5) / 100;
        _mint(p2eWalletOne, p2eTokens);

        uint256 remainingPercentage = (supply * 1 ether * 5) / 1000; // 0.5% as 5 / 1000

        _mint(p2eWalletTwo, remainingPercentage);
        _mint(p2eWalletThree, remainingPercentage);
        _mint(marketingWalletOne, remainingPercentage);
        _mint(marketingWalletTwo, remainingPercentage);
        _mint(marketingWalletThree, remainingPercentage);
        _mint(marketingWalletFour, remainingPercentage);
        _mint(marketingWalletFive, remainingPercentage);
        _mint(marketingWalletSix, remainingPercentage);
        _mint(marketingWalletSev, remainingPercentage);
        _mint(marketingWalletEig, remainingPercentage);
        _mint(marketingWalletNine, remainingPercentage);
        _mint(marketingWalletTen, remainingPercentage);

        isExcludedFromTaxes(deployerWallet);
        isExcludedFromTaxes(_pair);
        isExcludedFromTaxes(lpWallet);
        isExcludedFromTaxes(lpWalletOne);
        isExcludedFromTaxes(stakingWallet);
        isExcludedFromTaxes(cexWallet);
        isExcludedFromTaxes(marketingWallet);
        isExcludedFromTaxes(p2eWalletOne);
        isExcludedFromTaxes(p2eWalletTwo);
        isExcludedFromTaxes(p2eWalletThree);

        taxesEnabled = true;
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

            // Adjusted logic based on scenarios
            if (sender == _pair) {
                // Buy transaction
                if (!_isExcludedFromTaxes[recipient]) {
                    // Deduct buy taxes
                    taxAmount = (amount * buyTaxRate) / 1000;
                }
            } else if (recipient == _pair) {
                // Sell transaction
                if (!_isExcludedFromTaxes[sender]) {
                    // Deduct sell taxes
                    taxAmount = (amount * sellTaxRate) / 1000;
                }
            } else {
                // Regular transfer
                if (!_isExcludedFromTaxes[sender] && !_isExcludedFromTaxes[recipient]) {
                    // Deduct transfer taxes
                    taxAmount = (amount * transferTaxRate) / 1000;
                }
            }

            // Continue with the rest of the logic when taxAmount > 0
            if (taxAmount > 0) {
                // Deduct tax amount from the transferred amount
                uint256 netAmount = amount - taxAmount;

                // Distribute taxes
                distributeTaxes(sender, taxAmount);

                // Call parent implementation with the net amount after taxes
                super._transfer(sender, recipient, netAmount);
                return;
            }
        }

        // If taxes are disabled or no taxes to deduct, simply transfer the amount
        super._transfer(sender, recipient, amount);
    }

    function distributeTaxes(address sender, uint256 taxAmount) private {
        // Distribute taxes
        uint256 redistribution = (taxAmount * transferTaxes.redistribution) / 1000;
        super._transfer(sender, redistributionWallet, redistribution);

        uint256 lpAmount = (taxAmount * transferTaxes.lp) / 1000;
        super._transfer(sender, lpWalletOne, lpAmount);

        address[5] memory teamWallets = [
            0xe30828551bE2230cf6bfB39055D7557da4deb287,
            0xe63351353B064D99c652F64F86D0121CFAC74eF1,
            0x52f2D80c879C96209C4A7eB9b355a344ca6A132B,
            0x36F83890173C68Af527e4d74D581873490E7A0BC,
            0x04ae22013966860cf675C99AC43Ce613E2C5E30e
        ];

        uint256 teamShare = (taxAmount * transferTaxes.team) / 1000 / teamWallets.length;
        for (uint256 i = 0; i < teamWallets.length; i++) {
            super._transfer(sender, teamWallets[i], teamShare);
        }

        super._transfer(sender, marketingWallet, (taxAmount * transferTaxes.marketing) / 1000);
        super._transfer(sender, DEAD, (taxAmount * transferTaxes.burn) / 1000);
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

        // Ensure that the pair address can be set only once
        require(
            !pairAddressSet,
            "DragonCoin: Pair address can be set only once"
        );

        _pair = newPair;
        pairAddressSet = true;

        emit PairAddressUpdated(newPair);
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
