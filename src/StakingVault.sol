// src/StakingVault.sol
pragma solidity ^0.8.0;

import "./IERC20.sol"; // 导入定义的接口
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingVault is Ownable{
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

// 在 Day 4 的状态变量之后添加
function _updateReward() internal {
    // 检查是否有质押代币，如果没有，就没有奖励
    if (totalStaked == 0) {
        lastUpdateTime = block.timestamp;
        return;
    }

    // 1. 计算自上次更新到现在经过的时间 (duration)
    uint256 timeElapsed = block.timestamp - lastUpdateTime;
    
    // 2. 计算这段时间金库总共应发放的奖励 (reward)
    // 注意：rewardRate, timeElapsed, totalStaked 都是 uint256
    uint256 reward = timeElapsed * rewardRate; 

    // 3. 计算“每单位 TokenA 应该获得的奖励增量”
    // 这里涉及到大数除法，Solidity 中没有浮点数，但 totalStaked 是一个大数
    uint256 rewardPerTokenDelta = (reward * 1e18) / totalStaked; 
    // *1e18 是为了放大，保证精度，1e18 = 10**18 (类似 Java 的 BigInteger 精度处理)

    // 4. 更新全局累计值
    rewardPerTokenStored += rewardPerTokenDelta;

    // 5. 更新上次更新时间
    lastUpdateTime = block.timestamp;
}

// 在 _updateReward() 之后添加
function _calculateReward(address account) internal view returns (uint256) {
    // 1. 获取全局最新的 rewardPerTokenStored（包含本次更新）
    uint256 rewardPerToken = rewardPerTokenStored; 
    
    // 2. 获取用户自己的累计值
    uint256 userPaid = userRewardPerTokenPaid[account];
    
    // 3. 计算用户质押期间的增量奖励值 (Δ)
    uint256 accumulated = stakedBalance[account] * (rewardPerToken - userPaid);
    // 这里的 accumulated 依然是放大了 1e18 倍的，需要除以 1e18 还原

    // 4. 返回用户当前未领取的奖励 (已存奖励 + 本次计算新增奖励)
    return rewards[account] + (accumulated / 1e18); 
}

function claimReward() public {
    // 1. 更新全局奖励状态，并将用户未领取奖励计入 rewards[msg.sender]
    _updateReward(); 
    
    uint256 reward = rewards[msg.sender];
    require(reward > 0, "No rewards to claim");

    // 2. 将奖励代币 (Token B) 发送到用户地址
    // !!!注意：这一步是外部调用，易发生重入攻击（Day 11 解决）
    rewards[msg.sender] = 0; // 先清零，防止重入攻击（重要）
    
    // 3. 将 TokenB 转给用户
    rewardToken.transfer(msg.sender, reward);

    // 4. 更新用户的奖励累计值
    userRewardPerTokenPaid[msg.sender] = rewardPerTokenStored;
}

function withdraw(uint256 amount) public {
    require(amount > 0, "Amount must be greater than zero");
    require(stakedBalance[msg.sender] >= amount, "Insufficient staked balance");

    // 1. 领取所有未领取的奖励（确保在取款前计算并清算奖励）
    claimReward(); 

    // 2. 更新用户状态
    stakedBalance[msg.sender] -= amount;
    totalStaked -= amount;

    // 3. 将质押代币 (Token A) 发送到用户地址
    // !!!注意：这一步是外部调用，易发生重入攻击（Day 11 解决）
    stakingToken.transfer(msg.sender, amount);
    
    // 4. 更新时间戳和奖励累计值
    _updateReward();
}

function setRewardRate(uint256 newRate) public onlyOwner {
    // 先更新一次，防止管理员设置速率前产生奖励计算错误
    _updateReward(); 
    rewardRate = newRate;
}