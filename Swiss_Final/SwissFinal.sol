// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

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
