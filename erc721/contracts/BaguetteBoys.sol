// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract BaguetteBoys is ERC721, Pausable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant MAX_MINT_LIMIT = 10;
    uint256 public constant PUBLIC_SALE_PRICE = .00009 ether;
    uint256 public constant WHITELIST_SALE_PRICE = .00002 ether;

    bool public isRevealed;
    bool public publicSale;
    bool public whiteListSale;
    bytes32 private merkleRoot;
    string private baseTokenUri;

    mapping(address => uint256) private mintAddress;

    // events
    event _etherWidthdraw(uint256 _amount); 
    event _publicMinted(address owner, uint256 tokenId);
    event _whitelistMinted(address owner, uint256 amount);
    event _burnBox(address _address, uint256 _quantity);


    constructor() ERC721("BaguetteBoys", "BB") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Box :: Cannot be called by a contract");
        _;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint() external payable callerIsUser{
        uint256 tokenId = _tokenIdCounter.current();
        require(publicSale, "Public sale is not active!");
        require((totalSupply()) < MAX_SUPPLY, "All tokens sold!");
        require(msg.value >= PUBLIC_SALE_PRICE, "Payment is below the public sale price! ");
        require(mintAddress[msg.sender] < MAX_MINT_LIMIT, "Max mint per wallet limit reached!");
        
        mintAddress[msg.sender]++;
        _safeMint(msg.sender, tokenId);
        _tokenIdCounter.increment();
        emit _publicMinted(msg.sender, tokenId);
    }

    function whitelistMint(bytes32[] memory _merkleProof) external payable callerIsUser{
         uint256 tokenId = _tokenIdCounter.current();
        require(whiteListSale, "Whitelist sale is not active!");
        require((totalSupply()) < MAX_SUPPLY, "All tokens sold!");
        require(msg.value >= WHITELIST_SALE_PRICE,  "Payment is below the whitelist sale price!");
        require(mintAddress[msg.sender] < MAX_MINT_LIMIT, "Max mint per wallet limit reached!");
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), "You are not whitelisted!");
        
        mintAddress[msg.sender]++;
        _safeMint(msg.sender, tokenId);
        _tokenIdCounter.increment();
        emit _whitelistMinted(msg.sender, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function totalSupply() public view returns(uint256){
        return _tokenIdCounter.current();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }
   
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner{
        merkleRoot = _merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32){
        return merkleRoot;
    }

    function toggleWhiteListSale() external onlyOwner{
        whiteListSale = !whiteListSale;
    }

    function toggleReveal() external onlyOwner{
        isRevealed = !isRevealed;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function withdraw() external onlyOwner{
        emit _etherWidthdraw(address(this).balance);
        payable(msg.sender).transfer(address(this).balance);
    }
}