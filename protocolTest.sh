#!/bin/bash

#SETUP

#https://bitcoin.org/en/developer-examples#regtest-mode
#bitcoind -regtest -daemon
#bitcoin-cli -regtest generate 101
#bitcoin-cli -regtest getbalance

BLUE='\033[0;31m'

#A creating and funding ADDRESS_A
echo "A creating and funding ADDRESS_A..."
ADDRESS_A=$(bitcoin-cli -regtest getnewaddress)
echo "ADDRESS_A: $ADDRESS_A"
UTXO_TXID_A=$(bitcoin-cli -regtest sendtoaddress $ADDRESS_A 10.00)
echo "UTXO_TXID_A: UTXO_TXID_A"
echo

#A creating and funding ADDRESS_B
echo "A creating and funding ADDRESS_B..."
ADDRESS_B=$(bitcoin-cli -regtest getnewaddress)
echo "ADDRESS_B: $ADDRESS_B"
UTXO_TXID_B=$(bitcoin-cli -regtest sendtoaddress $ADDRESS_B 10.00)
echo "UTXO_TXID_B: UTXO_TXID_B"
echo

#A creating ADDRESS_TEMP_A
echo "A creating ADDRESS_TEMP_A..."
ADDRESS_TEMP_A=$(bitcoin-cli -regtest getnewaddress)
echo "ADDRESS_TEMP_A: $ADDRESS_TEMP_A"
echo

#A unsigned/unpublished tx: ADDRESS_A to ADDRESS_TEMP_A
echo "unsigned/unpublished tx: ADDRESS_A to ADDRESS_TEMP_A..."
RAW_TX_ADDRESS_TEMP_A=$(bitcoin-cli -regtest createrawtransaction '''
    [
      {
        "txid": "'$UTXO_TXID_A'",
        "vout": '0'
      }
    ]
    ''' '''
    {
      "'$ADDRESS_TEMP_A'": 10.00
    }''')
echo "RAW_TX_ADDRESS_TEMP_A: $RAW_TX_ADDRESS_TEMP_A"
TX_ADDRESS_TEMP_A=$(bitcoin-cli -regtest decoderawtransaction $RAW_TX_ADDRESS_TEMP_A)
echo "TX_ADDRESS_TEMP_A: $TX_ADDRESS_TEMP_A"
UTXO_TXID_ADDRESS_TEMP_A=$(grep -m 1 'txid' <<< "$TX_ADDRESS_TEMP_A" | cut -c15- | rev | cut -c3- | rev)
echo "UTXO_TXID_ADDRESS_TEMP_A: $UTXO_TXID_ADDRESS_TEMP_A"
echo

#B creating ADDRESS_TEMP_B
echo "B creating ADDRESS_TEMP_B..."
ADDRESS_TEMP_B=$(bitcoin-cli -regtest getnewaddress)
echo "ADDRESS_TEMP_B: $ADDRESS_TEMP_B"
echo

#B creating ADDRESS_ESCROW
echo "B creating ADDRESS_ESCROW..."
raw_multisig=$(bitcoin-cli -regtest createmultisig 2 '''
    [
      "'$ADDRESS_TEMP_A'",
      "'$ADDRESS_TEMP_B'"
    ]''')
echo

#B unsigned/unpublished tx: ADDRESS_B to ADDRESS_TEMP_B
echo "B unsigned/unpublished tx: ADDRESS_B to ADDRESS_TEMP_B..."
RAW_TX_ADDRESS_TEMP_B=$(bitcoin-cli -regtest createrawtransaction '''
    [
      {
        "txid": "'$UTXO_TXID_B'",
        "vout": '0'
      }
    ]
    ''' '''
    {
      "'$ADDRESS_TEMP_B'": 10.00
    }''')
echo "RAW_TX_ADDRESS_TEMP_B: $RAW_TX_ADDRESS_TEMP_B"
TX_ADDRESS_TEMP_B=$(bitcoin-cli -regtest decoderawtransaction $RAW_TX_ADDRESS_TEMP_B)
echo "TX_ADDRESS_TEMP_B: $TX_ADDRESS_TEMP_B"
UTXO_TXID_ADDRESS_TEMP_B=$(grep -m 1 'txid' <<< "$TX_ADDRESS_TEMP_B" | cut -c15- | rev | cut -c3- | rev)
echo "UTXO_TXID_ADDRESS_TEMP_B: $UTXO_TXID_ADDRESS_TEMP_B"
echo


#B signed/published tx: ADDRESS_TEMP_A & ADDRESS_TEMP_B to ADDRESS_ESCROW
echo "B signed/published tx: ADDRESS_TEMP_A & ADDRESS_TEMP_B to ADDRESS_ESCROW..."
ADDRESS_ESCROW=$(grep -m 1 'address' <<< "$raw_multisig" | cut -c18- | rev | cut -c3- | rev)
echo "ADDRESS_ESCROW: $ADDRESS_ESCROW"
REDEEM_SCRIPT=$(grep -m 1 'redeemScript' <<< "$raw_multisig" | cut -c23- | rev | cut -c2- | rev)
echo "REDEEM_SCRIPT: $REDEEM_SCRIPT"
PRIVKEY_ADDRESS_TEMP_B=$(bitcoin-cli -regtest dumpprivkey $ADDRESS_TEMP_B)
echo "PRIVKEY_ADDRESS_TEMP_B: $PRIVKEY_ADDRESS_TEMP_B"
RAW_TX_ESCROW=$(bitcoin-cli -regtest createrawtransaction '''
    [
      {
        "txid": "'$UTXO_TXID_ADDRESS_TEMP_A'", 
        "vout": '0'
      },
      {
        "txid": "'$UTXO_TXID_ADDRESS_TEMP_B'",
        "vout": '1'
      }
    ]
    ''' '''
    {
      "'$ADDRESS_ESCROW'": 20.00
    }''')
echo "RAW_TX_ESCROW: $RAW_TX_ESCROW"
echo "B Signing RAW_TX_ESCROW"
bitcoin-cli -regtest signrawtransaction $RAW_TX_ESCROW '[]' '''
    [
      "'$PRIVKEY_ADDRESS_TEMP_B'"
    ]'''
echo "B Sending RAW_TX_ESCROW"
bitcoin-cli -regtest sendrawtransaction $RAW_TX_ESCROW
echo

#A Pulls down tx: ADDRESS_TEMP_A & ADDRESS_TEMP_B to ADDRESS_ESCROW
echo "UNCOMPLETE: A Pulls down tx: ADDRESS_TEMP_A & ADDRESS_TEMP_B to ADDRESS_ESCROW..."
echo

#A Signs/Publishes tx: ADDRESS_A to ADDRESS_TEMP_A
echo "A Signs/Publishes tx: ADDRESS_A to ADDRESS_TEMP_A..."
PRIVKEY_ADDRESS_A=$(bitcoin-cli -regtest dumpprivkey $ADDRESS_A)
echo "PRIVKEY_ADDRESS_A: $PRIVKEY_ADDRESS_A"
echo "A Signing RAW_TX_ADDRESS_TEMP_A"
bitcoin-cli -regtest signrawtransaction $RAW_TX_ADDRESS_TEMP_A '[]' '''
    [
      "'$PRIVKEY_ADDRESS_A'"
    ]'''
echo "A Sending RAW_TX_ADDRESS_TEMP_A"
bitcoin-cli -regtest sendrawtransaction $RAW_TX_ADDRESS_TEMP_A
echo

#A Signs/Publishes tx: ADDRESS_TEMP_A & ADDRESS_TEMP_B to ADDRESS_ESCROW
echo "A Signs/Publishes tx: ADDRESS_TEMP_A & ADDRESS_TEMP_B to ADDRESS_ESCROW..."
PRIVKEY_ADDRESS_TEMP_A=$(bitcoin-cli -regtest dumpprivkey $ADDRESS_TEMP_A)
echo "PRIVKEY_ADDRESS_TEMP_A: $PRIVKEY_ADDRESS_TEMP_A"
echo "A Signing RAW_TX_ESCROW"
bitcoin-cli -regtest signrawtransaction $RAW_TX_ESCROW '[]' '''
    [
      "'$PRIVKEY_ADDRESS_TEMP_A'"
    ]'''
echo "A Sending RAW_TX_ESCROW"
bitcoin-cli -regtest sendrawtransaction $RAW_TX_ESCROW
echo

#A Signs/Publishes tx: REFUND
echo "A Signs/Publishes tx: REFUND..."
TX_ESCROW=$(bitcoin-cli -regtest decoderawtransaction $RAW_TX_ESCROW)
echo "TX_ESCROW: $TX_ESCROW"
UTXO_TXID_ESCROW=$(grep -m 1 'txid' <<< "$TX_ESCROW" | cut -c15- | rev | cut -c3- | rev)
echo "UTXO_TXID_ESCROW: $UTXO_TXID_ESCROW"
RAW_TX_REFUND=$(bitcoin-cli -regtest createrawtransaction '''
    [
      {
        "txid": "'$UTXO_TXID_ESCROW'",
        "vout": '0'
      }
    ]
    ''' '''
    {
      "'$ADDRESS_A'": 10.00,
      "'$ADDRESS_B'": 10.00
    }''')
echo "RAW_TX_REFUND: $RAW_TX_REFUND"
echo "A Signing RAW_TX_REFUND"
bitcoin-cli -regtest signrawtransaction $RAW_TX_REFUND '[]' '''
    [
      "'$PRIVKEY_ADDRESS_TEMP_A'"
    ]'''
echo "A Sending RAW_TX_REFUND"
bitcoin-cli -regtest sendrawtransaction $RAW_TX_REFUND
echo

#B Pulls down tx: REFUND
echo "UNCOMPLETE: Pulls down tx: REFUND..."
echo

#B Signs/Publishes tx: ADDRESS_B to ADDRESS_TEMP_B
echo "B Signs/Publishes tx: ADDRESS_B to ADDRESS_TEMP_B..."
PRIVKEY_ADDRESS_B=$(bitcoin-cli -regtest dumpprivkey $ADDRESS_B)
echo "PRIVKEY_ADDRESS_B: $PRIVKEY_ADDRESS_B"
bitcoin-cli -regtest signrawtransaction $RAW_TX_ADDRESS_TEMP_B '[]' '''
    [
      "'$PRIVKEY_ADDRESS_B'"
    ]'''
echo "Sending RAW_TX_ADDRESS_TEMP_B"
bitcoin-cli -regtest sendrawtransaction $RAW_TX_ADDRESS_TEMP_B
echo

#B Signs/Publishes tx: REFUND
echo "B Signs/Publishes tx: REFUND..."
echo "B Signing RAW_TX_REFUND"
bitcoin-cli -regtest signrawtransaction $RAW_TX_REFUND '[]' '''
    [
      "'$PRIVKEY_ADDRESS_TEMP_B'"
    ]'''
echo "B Sending RAW_TX_REFUND"
bitcoin-cli -regtest sendrawtransaction $RAW_TX_REFUND


