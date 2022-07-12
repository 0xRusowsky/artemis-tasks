import { Contract, ethers, providers, Wallet } from "ethers";

const GOERLI_RPC_URL = process.env.GOERLI_RPC_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const ADDRESS_TO = process.env.ADDRESS_TO;

const provider = new providers.StaticJsonRpcProvider(GOERLI_RPC_URL);
const wallet = new Wallet(PRIVATE_KEY);
const fromWallet = wallet.connect(provider);

const tx = await fromWallet.sendTransaction({
    to: ADDRESS_TO,
    value: 1e15,
    data: "0x53656e74206279205275736f77736b79203a29"
});

console.log("\ntx receipt:")
console.log(tx)

console.log("\n\ncheck the tx here:")
console.log(`https://goerli.etherscan.io/tx/${tx.hash}`)

/*
console.log("tx sent, waiting for confirmation /n ...");

const txReceipt = await tx.wait();

console.log(txReceipt);
console.log("from: ", txReceipt.from);
console.log("to: ", txReceipt.to);
console.log("value: ", txReceipt.value);
console.log("data: ", txReceipt.data);
*/