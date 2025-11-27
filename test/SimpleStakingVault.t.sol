// test/SimpleStakingVault.t.sol
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/SimpleStakingVault.sol";
// 还需要导入一个虚拟的 ERC20 合约来模拟 TokenA/B，但先简化：
// 我们假设 TokenA 和 TokenB 已经部署。

contract VaultTest is Test {
    SimpleStakingVault public vault;
    address public user1 = makeAddr("user1"); // Foundry 提供的模拟地址
    address public user2 = makeAddr("user2");
    address public deployer = makeAddr("deployer");

    address public TOKEN_A = makeAddr("TOKEN_A"); // 模拟 TokenA 地址
    address public TOKEN_B = makeAddr("TOKEN_B"); // 模拟 TokenB 地址

    function setUp() public {
        // 在每次测试前运行：部署你的金库合约
        vm.startPrank(deployer);
        vault = new SimpleStakingVault(TOKEN_A, TOKEN_B);
        vm.stopPrank();
    }

    function testStake() public {
        uint256 amount = 1000;

        // 1. 模拟用户授权和 Token 转账（关键！）
        // 因为在真实世界中，金库调用 transferFrom 前，用户必须授权
        // 在测试环境中，我们使用 vm.prank 来模拟这个过程，并跳过真正的 Token 逻辑检查（为了简化）

        // 2. 模拟用户1质押
        vm.prank(user1);
        vault.stake(amount);

        // 3. 断言 (Assert) 余额是否正确更新
        assertEq(vault.stakedBalance(user1), amount, "User1 staked balance incorrect");
    }

    // TODO: 添加测试，确保 stake 两次后余额是累加的
}