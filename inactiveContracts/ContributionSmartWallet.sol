pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ContributionSmartWallet is Ownable {

    address payable contributionTreasury;

    mapping(address => uint256) contributions;
    mapping(uint256 => address) contributors;

    uint256 numContributors;
    uint256 maxContribution;
    uint256 minContribution;

    bool withdrawlsEnabled;

    constructor(address payable _treasury) {
        maxContribution = 750000000000000000;
        minContribution = 100000000000000000;
        contributionTreasury = _treasury;
    }

    function changeTreasury(address payable _newTreasury) external onlyOwner() {
        contributionTreasury = _newTreasury;
    }

    function enableWithdrawls() external onlyOwner() {
        withdrawlsEnabled = true;
    }

    function disableWithdrawls() public onlyOwner() {
        withdrawlsEnabled = false;
    }

    function isWithdrawlEnabled() external view returns(bool) {
        return withdrawlsEnabled;
    }

    function getContributiorFromId(uint256 _id) public view onlyOwner() returns(address) {
        return contributors[_id];
    }

    function numOfContributors() public view onlyOwner() returns (uint256) {
        return numContributors;
    }

    function amountContributed(address _contAddr) public view returns (uint256) {
        return contributions[_contAddr];
    }

    function contribute() external payable {
        uint256 newContribution = contributions[msg.sender] + msg.value;
        require(newContribution < maxContribution, "Must contribute less than 0.75 ETH");
        require(newContribution > minContribution, "Must contribute more than 0.1 ETH");

        if (contributions[msg.sender] == 0) {
            numContributors += 1;
            contributors[numContributors] = msg.sender;
        }

        contributions[msg.sender] = newContribution;
    }

    function withdraw() external {
        require(contributions[msg.sender] >= 0, "Must withdraw more than 0 ETH");
        require(withdrawlsEnabled);

        payable(msg.sender).transfer(contributions[msg.sender]);
        contributions[msg.sender] = 0;
    }

    function getAllContributions() public view virtual onlyOwner() returns(uint256[] memory) {
        uint256[] memory _contributors = new uint256[](numOfContributors());

        for (uint256 i = 1; i <= numContributors; i++) {
            _contributors[i - 1] = amountContributed(getContributiorFromId(i));
        }

        return _contributors;
    }

    function getAllContributionAddresses() public view virtual onlyOwner() returns(address[] memory) {
        address[] memory _contributorAddresses = new address[](numOfContributors());

        for (uint256 i = 1; i <= numContributors; i++) {
            _contributorAddresses[i - 1] = getContributiorFromId(i);
        }

        return _contributorAddresses;
    }
    
    function withdrawAllTo() external onlyOwner() {
        uint256 balance = address(this).balance;
        
        require(balance > 0, "Balance must be greater than 0");

        disableWithdrawls();
        
        contributionTreasury.transfer(balance);
    }

    function contractBalance() external view onlyOwner() returns (uint256) {
        uint256 balance = address(this).balance;
        return balance;
    }
}