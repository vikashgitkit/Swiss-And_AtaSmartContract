// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// File: Swiss/Swiss.sol


pragma solidity >=0.4.22 <0.9.0;



contract Swiss is Ownable,  ReentrancyGuard  {
    struct BetGroup {
        uint256[] bets;
        address[] addresses;
        string[] avatars;
        string[] countries;
        uint256 total;
        uint256 distributedCount;
        uint256 totalDistributed;
    }

    struct Round {
        bool created;
        int32 startPrice;
        int32 endPrice; 
        uint256 minBetAmount;
        uint256 maxBetAmount;
        uint256 poolBetsLimit;
        BetGroup upBetGroup;
        BetGroup downBetGroup;
        int64 roundStartTime;
    }

    struct Distribution {
        uint256 winnersFeeAmt;
        uint256 fee;
        uint256 feeJackpot;
        uint256 feeService;
        uint256 totalFees;
        uint256 remainingWinAmt;
        uint256 remainingFeeAmt;
        uint256 pending;
    }

    address public gameController;
    mapping(bytes => Round) public pools;
    uint8 public feePercentage = 11;
    uint8 public feeJackpotPercentage = 1;
    uint8 public serviceFeePercentage = 1;
    address public feeAddress = msg.sender; 
    address public feeJackpotAddress = msg.sender; 
    address public serviceFeeAddress = msg.sender;
    bool public isRunning;
    bytes public notRunningReason;

    // Errors
    error PendingDistributions();

    // Events
    event RoundStarted(
        bytes poolId,
        int64 timestamp,
        int32 price,
        uint256 minTradeAmount,
        uint256 maxTradeAmount,
        uint256 poolTradesLimit,
        bytes indexed indexedPoolId
    );
    event RoundEnded(
        bytes poolId,
        int64 timestamp,
        int32 startPrice,
        int32 endPrice,
        bytes indexed indexedPoolId
    );
    event TradePlaced(
        bytes poolId,
        address sender,
        uint256 amount,
        string prediction,
        uint256 newTotal,
        bytes indexed indexedPoolId,
        address indexed indexedSender,
        string avatarUrl,
        string countryCode,
        int64 roundStartTime,
        string gameId
    );
    event TradeReturned(
        bytes poolId,
        address sender,
        uint256 amount
    );
    event GameStopped(bytes reason);
    event GameStarted();
    event RoundDistributed(
        bytes poolId,
        uint256 totalWinners,
        uint256 from,
        uint256 to,
        int64 timestamp
    );
    event TradeWinningsSent(
        bytes poolId,
        address sender,
        uint256 tradeAmount,
        uint256 winningsAmount,
        address indexed indexedSender,
        uint8 feePercentage,
        uint8 feeJackpotPercentage
    );

    constructor(address _newGameController)
        Ownable(_newGameController)
    {
        gameController = _newGameController;
    }

    // Modifiers
    modifier onlyOpenPool(bytes calldata poolId) {
        require(isPoolOpen(poolId), "This pool has a round in progress");
        _;
    }

    modifier onlyGameController() {
        require(
            msg.sender == gameController,
            "Only game controller can do this"
        );
        _;
    }

    modifier onlyGameRunning() {
        require(isRunning, "The game is not running");
        _;
    }

    modifier onlyPoolExists(bytes calldata poolId) {
        require(pools[poolId].created, "Pool does not exist");
        _;
    }

    function startGame() public onlyOwner {
        isRunning = true;
        notRunningReason = "";
        emit GameStarted();
    }

    function createPool(
        bytes calldata poolId,
        uint256 minBetAmount,
        uint256 maxBetAmount,
        uint256 poolBetsLimit
    ) public onlyGameController {
        pools[poolId].created = true;
        pools[poolId].minBetAmount = minBetAmount;
        pools[poolId].maxBetAmount = maxBetAmount;
        pools[poolId].poolBetsLimit = poolBetsLimit;
    }

    function isPoolOpen(bytes calldata poolId) public view returns (bool) {
        bool a = pools[poolId].startPrice == 0;
        return a;
    }

    function trigger(
        bytes calldata poolId,
        int64 timeMS,
        int32 price,
        uint32 batchSize
    ) public onlyGameController onlyPoolExists(poolId) {
        Round storage currentRound = pools[poolId];

        if (isPoolOpen(poolId)) {
            require(
                isRunning,
                "The game is not running, rounds can only be ended at this point"
            );
            currentRound.startPrice = price;
            currentRound.roundStartTime = timeMS;

            emit RoundStarted(
                poolId,
                timeMS,
                currentRound.startPrice,
                currentRound.minBetAmount,
                currentRound.maxBetAmount,
                currentRound.poolBetsLimit,
                poolId
            );
        } else if (currentRound.endPrice == 0) {
            currentRound.endPrice = price;

            emit RoundEnded(
                poolId,
                timeMS,
                currentRound.startPrice,
                currentRound.endPrice,
                poolId
            );

            distribute(poolId, batchSize, timeMS);
        } else {
            revert PendingDistributions();
        }
    }

    function returnBets(
        bytes calldata poolId,
        BetGroup storage group,
        uint32 batchSize
    ) private {
        uint256 pending = group.bets.length - group.distributedCount;
        uint256 limit = pending > batchSize ? batchSize : pending;
        uint256 to = group.distributedCount + limit;

        for (uint256 i = group.distributedCount; i < to; i++) {
            sendEther(group.addresses[i], group.bets[i]);
            emit TradeReturned(
                poolId,
                group.addresses[i],
                group.bets[i]
            );
        }

        group.distributedCount = to;
    }

    function distribute(
        bytes calldata poolId,
        uint32 batchSize,
        int64 timeMS
    ) public onlyGameController onlyPoolExists(poolId) nonReentrant {
        Round storage round = pools[poolId];
        if (
            round.upBetGroup.bets.length == 0 ||
            round.downBetGroup.bets.length == 0 ||
            (round.startPrice == round.endPrice)
        ) {
            if (round.startPrice == round.endPrice) {
                //In case of TIE return the investments to both sides
                BetGroup storage returnGroupUp = round.upBetGroup;
                BetGroup storage returnGroupDown = round.downBetGroup;

                uint256 fromReturnUp = returnGroupUp.distributedCount;
                uint256 fromReturnDown = returnGroupDown.distributedCount;
                returnBets(poolId, returnGroupUp, batchSize);
                returnBets(poolId, returnGroupDown, batchSize);

                emit RoundDistributed(
                    poolId,
                    returnGroupUp.bets.length,
                    fromReturnUp,
                    returnGroupUp.distributedCount,
                    timeMS
                );
                emit RoundDistributed(
                    poolId,
                    returnGroupDown.bets.length,
                    fromReturnDown,
                    returnGroupDown.distributedCount,
                    timeMS
                );

                if (
                    returnGroupUp.distributedCount ==
                    returnGroupUp.bets.length &&
                    returnGroupDown.distributedCount ==
                    returnGroupDown.bets.length
                ) {
                    clearPool(poolId);
                }
            } else {
                BetGroup storage returnGroup = round.downBetGroup.bets.length ==
                    0
                    ? round.upBetGroup
                    : round.downBetGroup;

                uint256 fromReturn = returnGroup.distributedCount;
                returnBets(poolId, returnGroup, batchSize);
                emit RoundDistributed(
                    poolId,
                    returnGroup.bets.length,
                    fromReturn,
                    returnGroup.distributedCount,
                    timeMS
                );

                if (returnGroup.distributedCount == returnGroup.bets.length) {
                    clearPool(poolId);
                }
            }

            return;
        }

        BetGroup storage winners = round.downBetGroup;
        BetGroup storage losers = round.upBetGroup;

        if (round.startPrice < round.endPrice) {
            winners = round.upBetGroup;
            losers = round.downBetGroup;
        }

        Distribution memory dist = calculateDistribution(winners, losers);
        uint256 limit = dist.pending > batchSize ? batchSize : dist.pending;
        uint256 to = winners.distributedCount + limit;

        for (uint256 i = winners.distributedCount; i < to; i++) {
            uint256 winnings = ((winners.bets[i] * dist.totalFees * 100) /
                winners.total /
                100);
            sendEther(
                winners.addresses[i],
                winnings +
                    (winners.bets[i] -
                        ((winners.bets[i] * feePercentage) / 100))
            );
            emit TradeWinningsSent(
                poolId,
                winners.addresses[i],
                winners.bets[i],
                winnings,
                winners.addresses[i],
                feePercentage,
                feeJackpotPercentage
            );
            winners.totalDistributed = winners.totalDistributed + winnings;
        }

        emit RoundDistributed(
            poolId,
            winners.bets.length,
            winners.distributedCount,
            to,
            timeMS
        );

        winners.distributedCount = to;
        if (winners.distributedCount == winners.bets.length) {
            sendEther(feeAddress, dist.remainingFeeAmt);
            sendEther(feeJackpotAddress, dist.feeJackpot);
            sendEther(serviceFeeAddress, dist.feeService);
            //Send leftovers to fee address
            sendEther(feeAddress, getContractBalance());

            clearPool(poolId);
        }
    }

    function calculateDistribution(
        BetGroup storage winners,
        BetGroup storage losers
    ) private view returns (Distribution memory) {
        uint256 feeAmt = ((winners.total + losers.total) * feePercentage) / 100;
        uint256 jackpotFeeAmount = (feeAmt * feeJackpotPercentage) / 100;
        uint256 serviceFeeAmount = (feeAmt * serviceFeePercentage) / 100;
        uint256 remainingFeeAmt = feeAmt -
            (jackpotFeeAmount + serviceFeeAmount);
        uint256 remainLoserAmt = losers.total -
            ((losers.total * feePercentage) / 100);
        uint256 remainWinnersAmt = winners.total -
            ((winners.total * feePercentage) / 100);
        uint256 pending = winners.bets.length - winners.distributedCount;

        return
            Distribution({
                winnersFeeAmt: (winners.total * feePercentage) / 100,
                fee: feeAmt,
                feeJackpot: jackpotFeeAmount,
                feeService: serviceFeeAmount,
                totalFees: remainLoserAmt,
                remainingWinAmt: remainWinnersAmt,
                remainingFeeAmt: remainingFeeAmt,
                pending: pending
            });
    }

    function clearPool(bytes calldata poolId) private {
        delete pools[poolId].upBetGroup;
        delete pools[poolId].downBetGroup;
        delete pools[poolId].startPrice;
        delete pools[poolId].endPrice;
    }

    function hasPendingDistributions(bytes calldata poolId)
        public
        view
        returns (bool)
    {
        return
            (pools[poolId].upBetGroup.bets.length +
                pools[poolId].downBetGroup.bets.length) > 0;
    }

    struct makeTradeStruct {
        bytes poolId;
        string avatarUrl;
        string countryCode;
        bool upOrDown;
        string gameId;
    }

    struct userDataStruct {
        string avatar;
        string countryCode;
        int64 roundStartTime;
        string gameId;
    }

    function addBet(
        BetGroup storage betGroup,
        uint256 amount,
        string calldata avatar,
        string calldata countryCode
    ) private returns (uint256) {
        betGroup.bets.push(amount);
        betGroup.addresses.push(msg.sender);
        betGroup.avatars.push(avatar);
        betGroup.countries.push(countryCode);
        betGroup.total += amount;
        return betGroup.total;
    }

    function makeTrade(makeTradeStruct calldata userTrade)
        public
        payable
        onlyOpenPool(userTrade.poolId)
        onlyGameRunning
        onlyPoolExists(userTrade.poolId)
    {
        require(isEOA(msg.sender), "must be EOA");
        require(msg.value > 0, "value must be greater than zero");
        require(
            msg.value >= pools[userTrade.poolId].minBetAmount,
            "amount should be higher than the minimum"
        );
        require(
            msg.value <= pools[userTrade.poolId].maxBetAmount,
            "amount should be lower than the maximum"
        );

           require(
        !isAddressInAnyBetGroup(pools[userTrade.poolId], msg.sender),
        "User has already placed a bet"
    );

        uint256 newTotal;

        if (userTrade.upOrDown) {
            require(
                pools[userTrade.poolId].upBetGroup.bets.length <=
                    pools[userTrade.poolId].poolBetsLimit - 1,
                "Pool is full, wait for next round"
            );
            newTotal = addBet(
                pools[userTrade.poolId].upBetGroup,
                msg.value,
                userTrade.avatarUrl,
                userTrade.countryCode
            );
        } else {
            require(
                pools[userTrade.poolId].downBetGroup.bets.length <=
                    pools[userTrade.poolId].poolBetsLimit - 1,
                "Pool is full, wait for next round"
            );
            newTotal = addBet(
                pools[userTrade.poolId].downBetGroup,
                msg.value,
                userTrade.avatarUrl,
                userTrade.countryCode
            );
        }

        userDataStruct memory userTradeData;
        userTradeData.avatar = userTrade.avatarUrl;
        userTradeData.countryCode = userTrade.countryCode;
        userTradeData.roundStartTime = pools[userTrade.poolId].roundStartTime;
        userTradeData.gameId = userTrade.gameId;

        emit TradePlaced(
            userTrade.poolId,
            msg.sender,
            msg.value,
            (userTrade.upOrDown) ? "UP" : "DOWN",
            newTotal,
            userTrade.poolId,
            msg.sender,
            userTradeData.avatar,
            userTradeData.countryCode,
            userTradeData.roundStartTime,
            userTradeData.gameId
        );
    }

     function isAddressInBetGroup(BetGroup storage betGroup, address user) private view returns (bool) {
        for (uint256 i = 0; i < betGroup.addresses.length; i++) {
            if (betGroup.addresses[i] == user) {
                return true;
            }
        }
        return false;
    }

    function isAddressInAnyBetGroup(Round storage round, address user) private view returns (bool) {
    return isAddressInBetGroup(round.upBetGroup, user) || isAddressInBetGroup(round.downBetGroup, user);
}

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function isEOA(address _addr) private view returns (bool) {
        // Checks if the caller is an EOA
        return _addr == tx.origin;
    }

    function sendEther(address to, uint256 amount) private {
        (bool sent, ) = payable(to).call{value: amount}("");
        require(sent, "Couldn't send ether");
    }

         // Function to change the minBetAmount and maxBetAmount
    function changeBetAmounts(bytes calldata poolId, uint256 newMinBetAmount, uint256 newMaxBetAmount) public onlyGameController onlyPoolExists(poolId) {
        require(newMinBetAmount <= newMaxBetAmount, "Minimum bet amount must be less than maximum bet amount");
        
        pools[poolId].minBetAmount = newMinBetAmount;
        pools[poolId].maxBetAmount = newMaxBetAmount;
    }

    function changeGameControllerAddress(address newGameControllerAddress)
        public
        onlyOwner
    {
        gameController = newGameControllerAddress;
    }

    function changeGameFeePercentage(uint8 newFeePercentage) public onlyOwner {
        require(newFeePercentage <= 100, "Wrong fee percentage value");
        feePercentage = newFeePercentage;
    }

    function changeGameFeeAddress(address newFeeAddress) public onlyOwner {
        feeAddress = newFeeAddress;
    }

    function changeGameFeeJackpotPercentage(uint8 newFeeJackpotPercentage)
        public
        onlyOwner
    {
        require(
            newFeeJackpotPercentage <= 100,
            "Wrong jackpot fee percentage value"
        );
        feeJackpotPercentage = newFeeJackpotPercentage;
    }

    function changeGameFeeJackpotAddress(address newFeeJackpotAddress)
        public
        onlyOwner
    {
        feeJackpotAddress = newFeeJackpotAddress;
    }

    function changeGameServiceFeeAddress(address newServiceFeeAddress)
        public
        onlyOwner
    {
        serviceFeeAddress = newServiceFeeAddress;
    }

    function changeGameServicePercentage(uint8 newFeeServicePercentage)
        public
        onlyOwner
    {
        require(
            newFeeServicePercentage <= 100,
            "Wrong Service fee percentage value"
        );
        serviceFeePercentage = newFeeServicePercentage;
    }

    function stopGame(bytes calldata reason) public onlyOwner {
        isRunning = false;
        notRunningReason = reason;
        emit GameStopped(reason);
    }
}
