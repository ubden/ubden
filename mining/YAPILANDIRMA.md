

## A ) 🎢 MINING HAVUZLARI 

- 1 ) https://ethermine.org/
- 2 ) https://www.sparkpool.com/
- 3 ) https://www.f2pool.com/
- 4 ) https://minepool.online/
- 5 ) https://nanopool.org/
- 6 ) https://www.nicehash.com/

## A ) 🎢 HASHRATE HESAPLAYICI

- 1 ) https://www.cryptocompare.com/mining/calculator/eth?HashingPower=75&HashingUnit=MH%2Fs&PowerConsumption=500&CostPerkWh=0.12&MiningPoolFee=1
- 2 ) https://www.nicehash.com/profitability-calculator/amd-rx-570-8gb
- 3 ) https://minerstat.com/mining-calculator
- 4 ) https://2cryptocalc.com/algo/now/etchash/25/
- 5 ) https://etherscan.io/ether-mining-calculator


## B ) ✨ CLAYMORE HAVUZ KULLANIMI START.BAT DOSYASI

ÖRNEK KULLANIM : 
===========================
Ethereum-only mining:

 ethermine:
 
```sh
EthDcrMiner64.exe -epool ssl://eu1.ethermine.org:5555 -ewal 0xD69af2A796A737A103F12d2f0BCC563a13900E6F -epsw x
```

 ethpool:
 
 ```sh
EthDcrMiner64.exe -epool us1.ethpool.org:3333 -ewal 0xD69af2A796A737A103F12d2f0BCC563a13900E6F -epsw x
```

 sparkpool:
 
```sh
EthDcrMiner64.exe -epool eu.sparkpool.com:3333 -ewal 0xD69af2A796A737A103F12d2f0BCC563a13900E6F -epsw x
```

 f2pool:
 
```sh
EthDcrMiner64.exe -epool eth.f2pool.com:8008 -ewal 0xd69af2a796a737a103f12d2f0bcc563a13900e6f -epsw x -eworker rig1
```

 nanopool:

```sh
EthDcrMiner64.exe -epool eth-eu1.nanopool.org:9999 -ewal 0xd69af2a796a737a103f12d2f0bcc563a13900e6f -epsw x -eworker rig1
```
 nicehash:
 
 ```sh
EthDcrMiner64.exe -epool stratum+tcp://daggerhashimoto.eu.nicehash.com:3353 -ewal 1LmMNkiEvjapn5PRY8A9wypcWJveRrRGWr -epsw x -esm 3 -allpools 1 -estale 0
```
Ethereum forks mining:

```sh
EthDcrMiner64.exe -epool exp-us.dwarfpool.com:8018 -ewal 0xd69af2a796a737a103f12d2f0bcc563a13900e6f -epsw x -allcoins -1
```

Ethereum SOLO mining (assume geth is on 192.168.0.1:8545):

```sh
EthDcrMiner64.exe -epool http://192.168.0.1:8545
```

===============================

## C.1 ) 🎇 DUALMINER (ÇİFT MADENCİ ÇALIŞTIRMA) CLAYMORE

Dual mining:

 ethpool, ethermine  (and Stratum for Decred): 
 ```sh
	EthDcrMiner64.exe -epool us1.ethpool.org:3333 -ewal 0xD69af2A796A737A103F12d2f0BCC563a13900E6F.YourWorkerName -epsw x -dpool stratum+tcp://yiimp.ccminer.org:3252 -dwal DsUt9QagrYLvSkJHXCvhfiZHKafVtzd7Sq4 -dpsw x
```
you can also specify "-esm 1" option to enable "qtminer" mode, in this mode pool will display additional information about shares (accepted/rejected), for example:
 ```sh
	EthDcrMiner64.exe -epool us1.ethermine.org:4444 -esm 1 -ewal 0xD69af2A796A737A103F12d2f0BCC563a13900E6F.YourWorkerName -epsw x -dpool stratum+tcp://yiimp.ccminer.org:3252 -dwal DsUt9QagrYLvSkJHXCvhfiZHKafVtzd7Sq4 -dpsw x
 ```
 ethpool, ethermine  (and Siacoin solo):
  ```sh
	EthDcrMiner64.exe -epool us1.ethpool.org:3333 -ewal 0xD69af2A796A737A103F12d2f0BCC563a13900E6F.YourWorkerName -epsw x -dpool http://localhost:9980/miner/header -dcoin sia
 ```
 ethpool, ethermine  (and Siacoin pool):
  ```sh
	EthDcrMiner64.exe -epool us1.ethpool.org:3333 -ewal 0xD69af2A796A737A103F12d2f0BCC563a13900E6F.YourWorkerName -epsw x -dpool http://sia-eu1.nanopool.org:9980/miner/header?address=3be0304dee313515cf401b8593a0c1df905ed13f0adaee89a8d7337d2ba8209e5ca9f297bbc2 -dcoin sia
 ```
 ethpool, ethermine  (and Siacoin pool with worker name):
  ```sh
   	EthDcrMiner64.exe -epool us1.ethpool.org:3333 -ewal 0xD69af2A796A737A103F12d2f0BCC563a13900E6F.YourWorkerName -epsw x -dpool http://sia-eu1.nanopool.org:9980/miner/header?"address=YourSiaAddress&worker=YourWorkerName" -dcoin sia
 ```
 same for siamining pool:
  ```sh
	EthDcrMiner64.exe -epool us1.ethpool.org:3333 -ewal 0xD69af2A796A737A103F12d2f0BCC563a13900E6F.YourWorkerName -epsw x -dpool "http://siamining.com:9980/miner/header?address=3be0304dee313515cf401b8593a0c1df905ed13f0adaee89a8d7337d2ba8209e5ca9f297bbc2&worker=YourWorkerName" -dcoin sia
 ```
 dwarfpool (and Stratum for Decred):
  ```sh
	EthDcrMiner64.exe -epool eth-eu.dwarfpool.com:8008 -ewal 0xD69af2A796A737A103F12d2f0BCC563a13900E6F/YourWorkerName -epsw x -dpool stratum+tcp://dcr.suprnova.cc:3252 -dwal Redhex.my -dpsw x
  ```
**Read dwarfpool FAQ for additional options, for example, you can setup email notifications if you specify your email as password.

 dwarfpool (and Stratum for Lbry):
  ```sh
	EthDcrMiner64.exe -epool eth-eu.dwarfpool.com:8008 -ewal 0xD69af2A796A737A103F12d2f0BCC563a13900E6F/YourWorkerName -epsw x -dpool stratum+tcp://lbry.suprnova.cc:6256 -dwal Redhex.my -dpsw x -dcoin lbc
  ```
  **Read dwarfpool FAQ for additional options, for example, you can setup email notifications if you specify your email as password.

 nanopool Ethereum+Siacoin:
  ```sh
EthDcrMiner64.exe -epool eth-eu1.nanopool.org:9999 -ewal YOUR_ETH_WALLET/YOUR_WORKER/YOUR_EMAIL -epsw x -dpool "http://sia-eu1.nanopool.org:9980/miner/header?address=YOUR_SIA_WALLET&worker=YOUR_WORKER_NAME&email=YOUR_EMAIL" -dcoin sia
  ```
 nanopool Ethereum+Siacoin(Stratum):
   ```sh
EthDcrMiner64.exe -epool eth-eu1.nanopool.org:9999 -ewal YOUR_ETH_WALLET/YOUR_WORKER/YOUR_EMAIL -epsw x -dpool stratum+tcp://sia-eu1.nanopool.org:7777 -dwal YOUR_SIA_WALLET/YOUR_WORKER/YOUR_EMAIL -dcoin sia
  ```
 nicehash Ethereum+Decred:
   ```sh
EthDcrMiner64.exe -epool stratum+tcp://daggerhashimoto.eu.nicehash.com:3353 -ewal 1LmMNkiEvjapn5PRY8A9wypcWJveRrRGWr -epsw x -esm 3 -allpools 1 -estale 0 -dpool stratum+tcp://decred.eu.nicehash.com:3354 -dwal 1LmMNkiEvjapn5PRY8A9wypcWJveRrRGWr
  ```
 miningpoolhub Ethereum+Siacoin:
   ```sh
	EthDcrMiner64.exe -epool us-east1.ethereum.miningpoolhub.com:20536 -ewal 0xD69af2A796A737A103F12d2f0BCC563a13900E6F -eworker YourLogin.YourWorkerName -epsw x -dpool stratum+tcp://hub.miningpoolhub.com:20550 -dwal username.workername -dpsw x -dcoin sia
   ```
 **you must also create worker "YourWorkerName" on pool and specify your wallet address there.

 suprnova Ethereum_Classic(ETC)+Siacoin:
   ```sh
	ethdcrminer64.exe -epool etc-eu.suprnova.cc:3333 -ewal YourLogin.YourWorkerName -epsw x -esm 3 -dpool sia.suprnova.cc:7777 -dwal YourLogin.YourWorkerName -dpsw x -dcoin sia -allpools 1 -allcoins -1
  ```
 coinotron:
   ```sh
	EthDcrMiner64.exe -epool coinotron.com:3344 -ewal Redhex.rig1 -esm 2 -epsw x -dpool http://dcr.suprnova.cc:9111 -dwal Redhex.my -dpsw x -allpools 1
  ```
 coinmine:
  ```sh
	EthDcrMiner64.exe -epool eth.coinmine.pl:4000 -ewal USERNAME.WORKER -esm 2 -epsw WORKER_PASS -allpools 1 -dpool stratum+tcp://dcr.coinmine.pl:2222 -dwal USERNAME.WORKER -dpsw WORKER_PASS
 ```
 ethpool+suprnova Ethereum+Pascal:
  ```sh
	ethdcrminer64.exe -epool us1.ethpool.org:3333 -ewal 0xD69af2A796A737A103F12d2f0BCC563a13900E6F.YourWorkerName -epsw x -dpool stratum+tcp://pasc.suprnova.cc:5279 -dwal YourLogin.YourWorkerName -dpsw x -dcoin pasc -allpools 1
 ```
 nicehash Ethereum+Blake2s:
  ```sh
EthDcrMiner64.exe -epool stratum+tcp://daggerhashimoto.eu.nicehash.com:3353 -ewal 1LmMNkiEvjapn5PRY8A9wypcWJveRrRGWr -epsw x -esm 3 -allpools 1 -estale 0 -dpool stratum+tcp://blake2s.eu.nicehash.com:3361 -dwal 1LmMNkiEvjapn5PRY8A9wypcWJveRrRGWr -dcoin blake2s
 ```
 nicehash Ethereum+Keccak:
  ```sh
EthDcrMiner64.exe -epool stratum+tcp://daggerhashimoto.eu.nicehash.com:3353 -ewal 1LmMNkiEvjapn5PRY8A9wypcWJveRrRGWr -epsw x -esm 3 -allpools 1 -estale 0 -dpool stratum+tcp://keccak.eu.nicehash.com:3338 -dwal 1LmMNkiEvjapn5PRY8A9wypcWJveRrRGWr -dcoin keccak
 ```


## C )  🐋 PHOENIXMINER HAVUZ KULLANIMI .START.BAT DOSYASI

ÖRNEK KULLANIM
===============================

ethermine.org (ETH):
 ```sh
      PhoenixMiner.exe -pool eu1.ethermine.org:4444 -pool2 us1.ethermine.org:4444 -wal YourEthWalletAddress.WorkerName -proto 3
 ```
ethermine.org (ETH, secure connection):
 ```sh
      PhoenixMiner.exe -pool ssl://eu1.ethermine.org:5555 -pool2 ssl://us1.ethermine.org:5555 -wal YourEthWalletAddress.WorkerName -proto 3
 ```
ethpool.org (ETH):
 ```sh
      PhoenixMiner.exe -pool eu1.ethpool.org:3333 -pool2 us1.ethpool.org:3333 -wal YourEthWalletAddress.WorkerName -proto 3
 ```
nanopool.org (ETH):
 ```sh
      PhoenixMiner.exe -pool eth-eu1.nanopool.org:9999 -wal YourEthWalletAddress/WorkerName -pass x
 ```
nicehash (ethash):
 ```sh
      PhoenixMiner.exe -pool stratum+tcp://daggerhashimoto.eu.nicehash.com:3353 -wal YourBtcWalletAddress -pass x -proto 4 -stales 0
 ```
f2pool (ETH):
 ```sh
      PhoenixMiner.exe -epool eth.f2pool.com:8008 -ewal YourEthWalletAddress -pass x -worker WorkerName
 ```
miningpoolhub (ETH):
 ```sh
      PhoenixMiner.exe -pool us-east.ethash-hub.miningpoolhub.com:20535 -wal YourLoginName.WorkerName -pass x -proto 1
 ```
coinotron.com (ETH):
 ```sh
      PhoenixMiner.exe -pool coinotron.com:3344 -wal YourLoginName.WorkerName -pass x -proto 1
 ```
ethermine.org (ETC):
 ```sh
      PhoenixMiner.exe -pool eu1-etc.ethermine.org:4444 -wal YourEtcWalletAddress.WorkerName -coin etc
 ```
epool.io (ETC):
 ```sh
      PhoenixMiner.exe -pool eu.etc.epool.io:8008 -pool2 us.etc.epool.io:8008 -worker WorkerName -wal YourEtcWalletAddress -pass x -retrydelay 2 -coin etc
 ```
whalesburg.com (ethash auto-switching):
 ```sh
      PhoenixMiner.exe -pool proxy.pool.whalesburg.com:8082 -wal YourEthWalletAddress -worker WorkerName -proto 2
 ```
miningpoolhub (EXP):
 ```sh
      PhoenixMiner.exe -pool us-east.ethash-hub.miningpoolhub.com:20565 -wal YourLoginName.WorkerName -pass x -proto 1
 ```
miningpoolhub (MUSIC):
 ```sh
      PhoenixMiner.exe -pool europe.ethash-hub.miningpoolhub.com:20585 -wal YourLoginName.WorkerName -pass x -proto 1
 ```
maxhash.org (UBIQ):
 ```sh
      PhoenixMiner.exe -pool ubiq-us.maxhash.org:10008 -wal YourUbqWalletAddress -worker WorkerName -coin ubq
 ```
ubiq.minerpool.net (UBIQ):
 ```sh
      PhoenixMiner.exe -pool lb.geo.ubiqpool.org:8001 -wal YourUbqWalletAddress -pass x -worker WorkerName -coin ubq
 ```
ubiqpool.io (UBIQ):
 ```sh
      PhoenixMiner.exe -pool eu2.ubiqpool.io:8008 -wal YourUbqWalletAddress.WorkerName -pass x -proto 4 -coin ubq
 ```
minerpool.net (PIRL):
 ```sh
      PhoenixMiner.exe -pool pirl.minerpool.net:8002 -wal YourPirlWalletAddress -pass x -worker WorkerName
 ```
etp.2miners.com (Metaverse ETP):
 ```sh
      PhoenixMiner.exe -pool etp.2miners.com:9292 -wal YourMetaverseETPWalletAddress -worker Rig1 -pass x
 ```
minerpool.net (Ellaism):
 ```sh
      PhoenixMiner.exe -pool ella.minerpool.net:8002 -wal YourEllaismWalletAddress -worker Rig1 -pass x
 ```
etherdig.net (ETH PPS):
 ```sh
      PhoenixMiner.exe -pool etherdig.net:4444 -wal YourEthWalletAddress.WorkerName -proto 4 -pass x
 ```
etherdig.net (ETH HVPPS):
 ```sh
      PhoenixMiner.exe -pool etherdig.net:3333 -wal YourEthWalletAddress.WorkerName -proto 4 -pass x
 ```
epool.io (CLO):
 ```sh
      PhoenixMiner.exe -pool eu.clo.epool.io:8008 -pool2 us.clo.epool.io:8008 -worker WorkerName -wal YourEthWalletAddress -pass x -coin clo -retrydelay 2
 ```
baikalmine.com (CLO):
 ```sh
      PhoenixMiner.exe -pool clo.baikalmine.com:3333 -wal YourEthWalletAddress -pass x -coin clo -worker rigName
  ```
=========================

## C.1 ) 🎇 DUALMINER (ÇİFT MADENCİ ÇALIŞTIRMA) PHOENIXMINER 

ETH on ethermine.org ETH, Blake2s on Nicehash:
 ```sh
      PhoenixMiner.exe -pool ssl://eu1.ethermine.org:5555 -pool2 ssl://us1.ethermine.org:5555 -wal YourEthWalletAddress.WorkerName -proto 3 -dpool blake2s.eu.nicehash.com:3361 -dwal YourBtcWalletAddress -dcoin blake2s
 ```
Nicehash (Ethash + Blake2s):
 ```sh
      PhoenixMiner.exe -pool stratum+tcp://daggerhashimoto.eu.nicehash.com:3353 -wal YourBtcWalletAddress -pass x -proto 4 -stales 0 -dpool blake2s.eu.nicehash.com:3361 -dwal YourBtcWalletAddress -dcoin blake2s
 ```

