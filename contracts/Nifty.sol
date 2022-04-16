// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IERC721.sol";

contract Nifty is ERC721, ERC721Metadata {

    mapping (address => uint256 ) private balances; // address to amount of NFT

    mapping (uint256 => address ) private ownership; // token Id to owner address

    mapping (uint256 => address ) private approvals; // token Id to approved address 

    mapping( address => address ) private operators; // approved operator for the address 

    mapping (uint256 => NiftyToken ) private nifties;

    string private t_name;

    string private t_symbol;

    uint256 private max_supply;

    uint256 private tokens_minted;

    uint256 private eth_ico;

    address owner;

    struct NiftyToken {

        uint256 token_id;

        bytes data;

        address nft_owner;

        string token_uri;
    }


    event NiftyTokenMinted(uint256 token_id, address owner, string token_uri);


    
    constructor(string memory _name, string memory _symbol, uint256 _max_supply, uint256 _eth_ico) {
       
       t_name = _name;
       t_symbol = _symbol;
       max_supply = _max_supply;
       tokens_minted = 0; 
       owner = msg.sender;
       eth_ico = _eth_ico;

    }


    modifier onlyOwner() {
        require(msg.sender == owner, "only the contract owner can call this function");
        _;
    }


    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) override external view returns (uint256) {
        
        require( _owner != 0x0000000000000000000000000000000000000000 , "invalid ownership, cannot be the 0x0 address");

        return balances[_owner];
    }

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) override external view returns (address) {

        address _owner = ownership[_tokenId];
        
        require( _owner != 0x0000000000000000000000000000000000000000 , "invalid ownership. this token id is associated to the 0x0 address");
        
        return _owner;
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param _data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) override external payable {

        address current_owner = ownership[_tokenId];

        require(current_owner != 0x0000000000000000000000000000000000000000, "the specified token does not have any owner or is not a valid token");

        require(_to != 0x0000000000000000000000000000000000000000, "the to address cannot be the NULL address");

        bool transfer_approved = msg.sender == current_owner || msg.sender == operators[_from];

        require(transfer_approved, "the from address is not the NFT owner or an approved operator");

        ownership[_tokenId] = _to; // given I have an array of nifties this is probably redundant

        balances[_from] = balances[_from] - 1;

        balances[_to] = balances[_to] + 1;

        nifties[_tokenId].nft_owner = _to;

        nifties[_tokenId].data = _data; // not sure this is correct.

    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) override external payable {
         this.safeTransferFrom(_from, _to, _tokenId, "");
    }

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) override external payable {

    }

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) override external payable {

        require(_approved != 0x0000000000000000000000000000000000000000, "the approved address cannot be the NULL address");

        require(ownership[_tokenId] == msg.sender, "the message sender is not the token owner");

        approvals[_tokenId] = _approved;

    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) override external {
        
        if( _approved == true ) {
           operators[msg.sender] = _operator;
        }
        else {
           operators[msg.sender] = 0x0000000000000000000000000000000000000000;
        }

    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) override external view returns (address) {
        
        require(ownership[_tokenId] != 0x0000000000000000000000000000000000000000, "Not a valid token id");
        
        return approvals[_tokenId];
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) override external view returns (bool) {
        
        require( _owner != 0x0000000000000000000000000000000000000000, "owner cannot be then 0x0 address");
        require( _operator != 0x0000000000000000000000000000000000000000, "operator cannot be then 0x0 address");
        return (operators[_owner] == _operator);
        
    }

      /// @notice A descriptive name for a collection of NFTs in this contract
    function name() override external view returns (string memory) {
      return t_name;
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() override external view returns (string memory) {
       return t_symbol;
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) override external view returns ( string memory) {
        // check if tokenId is valid
        require(ownership[_tokenId] != 0x0000000000000000000000000000000000000000, "token ID is not a valid identifier");

        return nifties[_tokenId].token_uri;
    }


    function _mint(string memory _token_uri, address _nft_owner) internal returns ( uint256 token_id) {

        require( tokens_minted < max_supply, "unable to mint more tokens. Max supply reached" );

        // generate a new tokenId
        token_id = tokens_minted++;

        NiftyToken memory token;

        token.token_id = token_id;
        token.token_uri = _token_uri;  // shall I check for uri uniqueness? 
        token.nft_owner = _nft_owner; // the owner of the token is the contract owner

        nifties[token_id] = token;

        // set ownership
        ownership[token_id] = _nft_owner;

        unchecked {

            balances[_nft_owner] = balances[_nft_owner] + 1;
            
        }
        

        return token_id;

    }

    function mint(string memory _token_uri) external payable onlyOwner returns (uint256) {

         require( msg.value >= eth_ico, "the amount of eth specified is below the price for this token");
         
         uint256 token_id = _mint(_token_uri, msg.sender);

         emit NiftyTokenMinted(token_id, msg.sender, _token_uri);

         return token_id;

    }

    function _burn(uint256 _token_id) internal returns ( bool ) {
       
       // burning means: remove it from nifities, etc..
       address _owner = ownership[_token_id];

       require(_owner != 0x0000000000000000000000000000000000000000, "this token id is invalid. Won't be burned");

       NiftyToken storage nifty = nifties[_token_id];

       nifty.nft_owner = 0x0000000000000000000000000000000000000000;
       nifty.token_id = 0;
       
       return false;
    }
}