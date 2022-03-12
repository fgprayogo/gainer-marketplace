// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "hardhat/console.sol";

contract GainerMarketplace{
    constructor (IERC20 erc20token) {
        _erc20token = erc20token;
    }

    IERC20 private _erc20token;                     /// @notice USDT ADDRESS POLYGON
    IERC1155 private _gainerNFT;                    /// @notice GAINER NFT

    address private _gainerMarketplaceTokenHolder;  /// @notice GAINER MARKETPLACE TOKEN HOLDER
    uint public _gainerNFTprice = 10000000;         /// @notice GAINER NFT BASE PRICE
    uint private _time;                             /// @notice TIME
    uint private _multiplier = 1;                   /// @notice MULTIPLIER
    uint private currentDay;                        /// @notice CURRENT DAY
    uint private nextDay;                           /// @notice NEXT DAY
    
    mapping(address => uint256) public userErc20TokenBalanceInGainerProtocol;  /// @notice @param useraddress 
    mapping(uint => mapping(uint => NFTListing)) public Listing; /// @notice @param tokenId, @param listingId
    mapping(address => mapping(uint=> uint)) public UserListing; /// @notice @param sellerAddr @param tokenId, @param listingId
    
    uint constant public headGainerOne  = 0; /// @notice CURRENT LISTING GAINER ONE
    uint public tailGainerOne           = 0; /// @notice LAST LISTING GAINER ONE
    uint constant public headGainerFive = 0; /// @notice CURRENT LISTING GAINER FIVE
    uint public tailGainerFive          = 0; /// @notice LAST LISTING GAINER FIVE
    uint constant public headGainerTen  = 0; /// @notice CURRENT LISTING GAINER TEN
    uint public tailGainerTen           = 0; /// @notice LAST LISTING GAINER TEN

    struct NFTListing{
        uint prev;
        uint selfIndex;
        uint next;
        address sellerAddr;
        uint amount;
    }

    event AddListing(address sellerAddr, uint256 listingId, uint256 tokenId, uint256 amount);
    event DoneTrx(address sellerAddr, uint256 listingId, uint256 tokenId, uint256 amount, address buyerAddr, string note);
    event DoneTrxGainerOne(address indexed sellerAddr, uint256 listingId, uint256 indexed amount, address indexed buyerAddr, string note);
    event DoneTrxGainerFive(address indexed sellerAddr, uint256 listingId, uint256 indexed amount, address indexed buyerAddr, string note);
    event DoneTrxGainerTen(address indexed sellerAddr, uint256 listingId, uint256 indexed amount, address indexed buyerAddr, string note);
    event ModifyListing(address sellerAddr, uint256 listingId, uint256 tokenId, uint256 amount, uint prevListingId);
    
    function setupDay(uint _nextDay) public {
        nextDay = _nextDay;
    }
    
    function showPrice() public view returns(uint){
        if(block.timestamp > nextDay){
            uint dayDifferent = (block.timestamp - nextDay) / 60 / 60 / 24;
            if(dayDifferent == 0){
                return _gainerNFTprice;
            }else{
                uint _gainerBasePrice = _gainerNFTprice;
                for(uint i = 0 ; i < dayDifferent; i++){
                    _gainerBasePrice += _gainerNFTprice * _multiplier / 100;
                }
                return _gainerBasePrice;
            }
        }else{
             return _gainerNFTprice;
        }
    }

    function updatePrice() internal {
        if(block.timestamp > nextDay){
            uint dayDifferent = (block.timestamp - nextDay) / 60 / 60 / 24;
            if(dayDifferent > 0){
                uint _gainerBasePrice = _gainerNFTprice;
                for(uint i = 0 ; i < dayDifferent; i++){
                    _gainerBasePrice += _gainerNFTprice * _multiplier / 100;
                    nextDay += 1 days;
                }
                _gainerNFTprice = _gainerBasePrice;
            }
        }
    }
    
    function isEmpty(uint tokenId, uint head) public view returns(bool){
        return(Listing[tokenId][head].next == 0);   
    }

    function checkUserListing(uint tokenId)public view returns(bool){
        return(UserListing[msg.sender][tokenId]==0);
    }

    function checkTopListing(uint tokenId)public view returns(NFTListing memory){
        NFTListing memory listing;
        if(tokenId == 0){
            uint _listingId = Listing[tokenId][headGainerOne].next;
            listing = Listing[tokenId][_listingId];
        }else if(tokenId == 1){
            uint _listingId = Listing[tokenId][headGainerFive].next;
            listing = Listing[tokenId][_listingId];
        }else if(tokenId == 3){
            uint _listingId = Listing[tokenId][headGainerFive].next;
            listing = Listing[tokenId][_listingId];
        }
        return listing;
    }
    
    function checkLastListing(uint tokenId)public view returns(NFTListing memory){
        NFTListing memory listing;
        if(tokenId == 0){
            uint _listingId = Listing[tokenId][tailGainerOne].selfIndex;
            listing = Listing[tokenId][_listingId];
        }else if(tokenId == 1){
            uint _listingId = Listing[tokenId][tailGainerFive].selfIndex;
            listing = Listing[tokenId][_listingId];
        }else if(tokenId == 3){
            uint _listingId = Listing[tokenId][tailGainerTen].selfIndex;
            listing = Listing[tokenId][_listingId];
        }
        return listing;
    }

    function addListingNFT(uint tokenId, uint amount)public{
        require(tokenId == 0 || tokenId == 1 || tokenId == 2, "NOT ALLOWED");
        require(checkUserListing(tokenId), "YOU ALREADY HAVE A LISTING");
        
        _gainerNFT.safeTransferFrom(msg.sender, _gainerMarketplaceTokenHolder, tokenId, amount, "");
        
        if(tokenId == 0){
            if(isEmpty(tokenId, headGainerOne)){
                Listing[tokenId][headGainerOne].next = 1;
                Listing[tokenId][1] = NFTListing(0, 1 ,0, msg.sender, amount);
                tailGainerOne = 1;
                UserListing[msg.sender][tokenId] = 1;
                emit AddListing(msg.sender, 1, tokenId, amount);
            }else{
                Listing[tokenId][tailGainerOne].next = tailGainerOne+1;
                Listing[tokenId][tailGainerOne+1] = NFTListing(tailGainerOne, tailGainerOne+1, 0, msg.sender, amount);
                UserListing[msg.sender][tokenId] = tailGainerOne+1;
                if(tailGainerOne == type(uint).max){
                    tailGainerOne = 1;
                }else  {
                    tailGainerOne++;
                }
                emit AddListing(msg.sender, tailGainerOne, tokenId, amount);
        }
        }else if(tokenId == 1){
           if(isEmpty(tokenId, headGainerFive)){
                Listing[tokenId][headGainerFive].next = 1;
                Listing[tokenId][1] = NFTListing(0, 1 ,0, msg.sender, amount);
                tailGainerFive = 1;
                UserListing[msg.sender][tokenId] = 1;
                emit AddListing(msg.sender, 1, tokenId, amount);
            }else{
                Listing[tokenId][tailGainerFive].next = tailGainerFive+1;
                Listing[tokenId][tailGainerFive+1] = NFTListing(tailGainerFive, tailGainerFive+1, 0, msg.sender, amount);
                UserListing[msg.sender][tokenId] = tailGainerFive+1;
                if(tailGainerOne == type(uint).max){
                    tailGainerOne = 1;
                }else  {
                    tailGainerOne++;
                }
                emit AddListing(msg.sender, tailGainerFive, tokenId, amount);
            }
        }else{
            if(isEmpty(tokenId, headGainerTen)){
                Listing[tokenId][headGainerTen].next = 1;
                Listing[tokenId][1] = NFTListing(0, 1 ,0, msg.sender, amount);
                tailGainerTen = 1;
                UserListing[msg.sender][tokenId] = 1;
                emit AddListing(msg.sender, 1, tokenId, amount);
            }else{
                Listing[tokenId][tailGainerTen].next = tailGainerTen+1;
                Listing[tokenId][tailGainerTen+1] = NFTListing(tailGainerTen, tailGainerTen+1, 0, msg.sender, amount);
                UserListing[msg.sender][tokenId] = tailGainerTen+1;
               if(tailGainerOne == type(uint).max){
                    tailGainerOne = 1;
                }else  {
                    tailGainerOne++;
                }
                emit AddListing(msg.sender, tailGainerTen, tokenId, amount);
            }
        }
    }

    function buyNFT(uint moneyAmount, uint tokenId, uint tokenAmount) public returns(bool){
        updatePrice();

        uint gainerNFTprice;
        if(tokenId == 0){
            gainerNFTprice = _gainerNFTprice;
        }else if(tokenId == 1){
            gainerNFTprice = _gainerNFTprice * 5;
        }else{
            gainerNFTprice = _gainerNFTprice * 10;
        }

        require(tokenId == 0 || tokenId == 1 || tokenId == 2, "NOT ALLOWED");
        require(moneyAmount == tokenAmount * gainerNFTprice, "MONEY AMOUNT MUST MATCH");
        uint _protocolGtokenBalance = _gainerNFT.balanceOf(_gainerMarketplaceTokenHolder, tokenId); //chek seller gtoken balance in wallet
        require(tokenAmount <= _protocolGtokenBalance, "OUT OF STOCK");
        
        _erc20token.transferFrom(msg.sender, address(this), moneyAmount); //transfer buyer money to protocol

        uint _tokenAmount = tokenAmount;
        NFTListing memory _headListing;

        if(tokenId == 0){
            _headListing = Listing[tokenId][headGainerOne];
        }else if(tokenId == 1){
            _headListing = Listing[tokenId][headGainerFive];
        }else{
            _headListing = Listing[tokenId][headGainerTen];
        }

        NFTListing storage _sellerListing = Listing[tokenId][_headListing.next];
        while(_tokenAmount != 0){
            console.log("Token Amount : " , _tokenAmount); 
            if(_tokenAmount > _sellerListing.amount){
                uint erc20seller            = gainerNFTprice * _sellerListing.amount;
                     _tokenAmount          -= _sellerListing.amount;
                console.log("BUYING FROM > SELLER TOKEN " , _sellerListing.amount);
                     uint amountTraded = _sellerListing.amount;
                     _sellerListing.amount  = 0;


                if(tokenId == 0){
                    if(_sellerListing.selfIndex == tailGainerOne){
                        tailGainerOne = Listing[tokenId][tailGainerOne].prev;
                    }
                }else if(tokenId == 1){
                   if(_sellerListing.selfIndex == tailGainerFive){
                        tailGainerFive = Listing[tokenId][tailGainerFive].prev;
                    }
                }else{
                    if(_sellerListing.selfIndex == tailGainerTen){
                        tailGainerTen = Listing[tokenId][tailGainerTen].prev;
                    }
                }
                
                uint256 a                = Listing[tokenId][_sellerListing.selfIndex].prev;
                uint256 b                = Listing[tokenId][_sellerListing.selfIndex].next;
                Listing[tokenId][a].next = Listing[tokenId][_sellerListing.selfIndex].next;
                Listing[tokenId][b].prev = Listing[tokenId][_sellerListing.selfIndex].prev;

                userErc20TokenBalanceInGainerProtocol[_sellerListing.sellerAddr] += erc20seller; 

                NFTListing storage nextData = Listing[tokenId][_sellerListing.next];

                
                if(tokenId == 0){
                    emit DoneTrxGainerOne(_sellerListing.sellerAddr, _sellerListing.selfIndex, amountTraded, msg.sender, "");
                }else if(tokenId == 1){
                    emit DoneTrxGainerFive(_sellerListing.sellerAddr, _sellerListing.selfIndex, amountTraded, msg.sender, "");
                }else{
                    emit DoneTrxGainerTen(_sellerListing.sellerAddr, _sellerListing.selfIndex, amountTraded, msg.sender, "");
                }

                delete UserListing[_sellerListing.sellerAddr][tokenId];
                delete Listing[tokenId][_sellerListing.selfIndex];                
                _sellerListing = nextData;
                console.log("BUYING FROM > BUYER TOKEN" , _tokenAmount);
            }else if(_tokenAmount < _sellerListing.amount){
                 uint erc20seller            = gainerNFTprice * _tokenAmount;
                 uint amountTraded           = _tokenAmount;
                      _sellerListing.amount -= _tokenAmount;
                      _tokenAmount           = 0;

                userErc20TokenBalanceInGainerProtocol[_sellerListing.sellerAddr] += erc20seller; 

                if(tokenId == 0){
                    emit DoneTrxGainerOne(_sellerListing.sellerAddr, _sellerListing.selfIndex, amountTraded, msg.sender, "");
                }else if(tokenId == 1){
                    emit DoneTrxGainerFive(_sellerListing.sellerAddr, _sellerListing.selfIndex,  amountTraded, msg.sender, "");
                }else{
                    emit DoneTrxGainerTen(_sellerListing.sellerAddr, _sellerListing.selfIndex, amountTraded, msg.sender, "");
                }

                console.log("BUYING FROM < SELLER TOKEN ", _sellerListing.amount);   
                console.log("BUYING FROM < BUYER TOKEN", _tokenAmount);   
            }else if(_tokenAmount == _sellerListing.amount){
                uint erc20seller  = gainerNFTprice * _sellerListing.amount;
                uint amountTraded = _sellerListing.amount;
                     _tokenAmount = 0;
                console.log("BUYING FROM = SELLER TOKEN", _sellerListing.amount);   
                _sellerListing.amount = 0;
                 userErc20TokenBalanceInGainerProtocol[_sellerListing.sellerAddr] += erc20seller; 

                if(tokenId == 0){
                    if(_sellerListing.selfIndex == tailGainerOne){
                        tailGainerOne =  Listing[tokenId][tailGainerOne].prev;
                    }
                }else if(tokenId == 1){
                   if(_sellerListing.selfIndex == tailGainerFive){
                        tailGainerFive =  Listing[tokenId][tailGainerFive].prev;
                    }
                }else{
                    if(_sellerListing.selfIndex == tailGainerTen){
                        tailGainerTen =  Listing[tokenId][tailGainerTen].prev;
                    }
                }

                uint256 a =  Listing[tokenId][_sellerListing.selfIndex].prev;
                uint256 b = Listing[tokenId][_sellerListing.selfIndex].next;

                Listing[tokenId][a].next = Listing[tokenId][_sellerListing.selfIndex].next;
                Listing[tokenId][b].prev = Listing[tokenId][_sellerListing.selfIndex].prev;
       
                NFTListing storage nextData = Listing[tokenId][_sellerListing.next];

                if(tokenId == 0){
                    emit DoneTrxGainerOne(_sellerListing.sellerAddr, _sellerListing.selfIndex, amountTraded, msg.sender, "");
                }else if(tokenId == 1){
                    emit DoneTrxGainerFive(_sellerListing.sellerAddr, _sellerListing.selfIndex, amountTraded, msg.sender, "");
                }else{
                    emit DoneTrxGainerTen(_sellerListing.sellerAddr, _sellerListing.selfIndex,  amountTraded, msg.sender, "");
                }

                delete UserListing[_sellerListing.sellerAddr][tokenId];
                delete Listing[tokenId][_sellerListing.selfIndex];

                _sellerListing = nextData;
                console.log("BUYING FROM = BUYER TOKEN", _tokenAmount);   
            }
        }
        _gainerNFT.safeTransferFrom(_gainerMarketplaceTokenHolder, msg.sender, tokenId, tokenAmount, "");
        return true;
    }

    function addDoneTrx(uint i, address sellerAddr, uint listingId, uint tokenId, uint tokenAmount, bool isSubmit) internal {
       address[] memory _sellerAddr;
        uint[] memory _sellerListingId;
        uint[] memory _sellerListingAmount;

        if(!isSubmit){
            _sellerAddr[i] = sellerAddr;
            _sellerListingAmount[i] = tokenAmount;
            _sellerListingId[i] = listingId;
        }else if(isSubmit){
            for(uint j = 0 ; j<_sellerAddr.length; j++){
                emit DoneTrx(_sellerAddr[j], _sellerListingId[j], tokenId, _sellerListingAmount[j], msg.sender, "");
            }
        }
    }    
    
    function setGainerNFTurlAndGainerTokenHolder(IERC1155 gainerNFTaddr, address gainerMarketplaceTokenHolder) public returns(bool){
        _gainerNFT = gainerNFTaddr;
        _gainerMarketplaceTokenHolder = gainerMarketplaceTokenHolder;
        return true;
    }

    function withdrawUserERC20Token() public {
        uint _balance = userErc20TokenBalanceInGainerProtocol[msg.sender];
        require(_balance > 0, "Not enaugh balance");
        userErc20TokenBalanceInGainerProtocol[msg.sender] = 0;
        _erc20token.transfer(msg.sender, _balance); 
    }

    address private _protocolWalletAddr;

    function buyNFTFromGainerProtocol(uint moneyAmount, uint tokenId, uint tokenAmount) public {
        updatePrice();

        uint gainerNFTprice;
        if(tokenId == 0){
            gainerNFTprice = _gainerNFTprice;
        }else if(tokenId == 1){
            gainerNFTprice = _gainerNFTprice * 5;
        }else{
            gainerNFTprice = _gainerNFTprice * 10;
        }

        require(tokenId == 0 || tokenId == 1 || tokenId == 2, "NOT ALLOWED");
        require(moneyAmount == tokenAmount * gainerNFTprice, "MONEY AMOUNT MUST MATCH");
        uint _protocolGtokenBalance = _gainerNFT.balanceOf(_protocolWalletAddr, tokenId); 
        require(tokenAmount <= _protocolGtokenBalance, "OUT OF STOCK");
        
        _erc20token.transferFrom(msg.sender, _protocolWalletAddr, moneyAmount); 
        _gainerNFT.safeTransferFrom(_protocolWalletAddr, msg.sender, tokenId, tokenAmount, "");
    }

    function setProtocolWalletAddr(address protocolWalletAddr)public{
        _protocolWalletAddr = protocolWalletAddr;
    }

    address private _giveAwayWalletAddr;
    mapping(address => bool) public userClaimGiveAway;
    bool public isClaimOpen;
    
    function claimGiveAway()public{
        require(isClaimOpen, "NOT CLAIMABLE YET");
        uint _giveAwayWalletAddrGainerOneBalance = _gainerNFT.balanceOf(_giveAwayWalletAddr, 0); //chek seller gtoken balance in wallet
        uint _giveAwayWalletAddrGainerFiveBalance = _gainerNFT.balanceOf(_giveAwayWalletAddr, 1); //chek seller gtoken balance in wallet
        uint _giveAwayWalletAddrGainerTenBalance = _gainerNFT.balanceOf(_giveAwayWalletAddr, 2); //chek seller gtoken balance in wallet
        require(_giveAwayWalletAddrGainerOneBalance > 0 || _giveAwayWalletAddrGainerFiveBalance > 0 || _giveAwayWalletAddrGainerTenBalance > 0, "ALL NFTs ALREADY CLAIMED") ;
        if(userClaimGiveAway[msg.sender] == false){
            userClaimGiveAway[msg.sender] == true;
            if(_giveAwayWalletAddrGainerOneBalance > 0){
                _gainerNFT.safeTransferFrom(_giveAwayWalletAddr, msg.sender, 0, 10, "");
            }else if(_giveAwayWalletAddrGainerFiveBalance > 0){
                _gainerNFT.safeTransferFrom(_giveAwayWalletAddr, msg.sender, 1, 2, "");
            }else if(_giveAwayWalletAddrGainerTenBalance > 0){
                _gainerNFT.safeTransferFrom(_giveAwayWalletAddr, msg.sender, 2, 1, "");
            }
        }else{
            require(userClaimGiveAway[msg.sender] == false, "YOU ALREADY CLAIMED");
        }
    }

    function setGiveAwayWalletAddr(address giveAwayWalletAddr) public {
        _giveAwayWalletAddr = giveAwayWalletAddr;
    }

    function setStatusGiveaway(bool status) public {
        isClaimOpen = status;
    }

    IERC20 private _otherERC20Token;                     /// @notice USDT ADDRESS POLYGON

    function showOtherERC20Token() public view returns(IERC20){
        return _otherERC20Token;
    }

    function setOtherERC20Token(IERC20 addr) public {
        _otherERC20Token = addr;
    }

    function transferOtherERC20Token(address _to) public {
        uint _balance = _otherERC20Token.balanceOf(address(this));
        _otherERC20Token.transfer(_to, _balance); 
    }
}

