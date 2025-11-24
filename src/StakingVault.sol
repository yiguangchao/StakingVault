// src/StakingVault.sol
pragma solidity ^0.8.0;

import "./IERC20.sol"; // 导入定义的接口

contract StakingVault {
    // 质押代币 (TokenA) 和奖励代币 (TokenB) 的地址
    IERC20 public immutable stakingToken; 
    IERC20 public immutable rewardToken; 

    // 构造函数：合约部署时必须传入 TokenA 和 TokenB 的地址
    constructor(address _stakingToken, address _rewardToken) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }
}

    // 质押代币的映射（用于 Day 4 定义，但 Day 3 提前声明）
mapping(address => uint256) public stakedBalance;

function stake(uint256 amount) public {
    require(amount > 0, "Amount must be greater than zero");

    // 1. 将代币从调用者地址转入金库合约地址
    // 这一步要求用户已经提前授权 (approve) 金库合约有权转移这笔 amount
    bool success = stakingToken.transferFrom(
        msg.sender,
        address(this), // address(this) 就是当前金库合约的地址
        amount
    );
    require(success, "Token transfer failed");

    // 2. 更新用户的质押余额
    stakedBalance[msg.sender] += amount;

    // TODO: 调用奖励计算/更新函数
}

// 用户的质押余额 (用户地址 => 质押数量)
mapping(address => uint256) public stakedBalance;

// 记录用户上次参与时间或领取时间 (用户地址 => 时间戳)
mapping(address => uint256) public lastUpdateTime;

// 总奖励池中，每单位 TokenA 已经累积了多少 TokenB 奖励
// 这个变量是计算奖励的关键，需放大 10^18 倍处理
uint256 public rewardPerTokenStored;

// 当前金库中总共有多少 TokenA (用于计算总奖励率)
uint256 public totalStaked;

// 管理员设置的每秒奖励速率 (TokenB per second)
uint256 public rewardRate; 

// 记录用户历史累计的奖励值（用于和当前的 rewardPerTokenStored 进行比较）
// (用户地址 => 奖励累积值)
mapping(address => uint256) public userRewardPerTokenPaid;

// 用户未领取的奖励
mapping(address => uint256) public rewards;