const hre = require("hardhat");
const ethers = hre.ethers;
const fs = require("fs");
const path = require("path");
// const { network } = require("hardhat");

async function main() {
    if (network.name === 'hardhat') {
        console.warn(
            "You are trying to deploy a contract to the Hardhat Network, which" +
            "gets automatically created and destroyed every time. Use the Hardhat" +
            " option '--network localhost'"
        );
    }
    const [deployer] = await ethers.getSigners();
    console.log('Deploying with', await deployer.getAddress());
    const DutchAuction = await ethers.getContractFactory('DutchAuction', deployer);
    const auction = await DutchAuction.deploy(
        ethers.utils.parseEther('2.0'),
        1,
        'MotorBike'
    );
    await auction.deployed();

    // передаем развернутые контракты в saveFrontendFiles
    // этот объект будет обходиться в цикле и будет копировать нужные файлы 
    // нужно будет перенести файлы из artifacts/contracts/contract_name/contract_name.json в директорию front
    saveFrontendFiles({
        // название контракта: сам контракт
        DutchAuction: auction,
    })
}

// принимает контракты, которые хотим скопировать для фронтенда
function saveFrontendFiles(contracts) {
    // __dirname - текущая директория
    // из текущей директории сначала поднимается на уровень выше и идем в папку front/contracts
    const contractsDir = path.join(__dirname, './..', 'front/contracts');
    // если директории не существует, создаем её
    if (!fs.existsSync(contractsDir)) {
        fs.mkdirSync(contractsDir);
    }
    Object.entries(contracts).forEach((contractItem) => {
        const [name, contract] = contractItem;
        if (contract) {
            // создаем файл, в котором будет адрес смарт контракта
            fs.writeFileSync(
                path.join(contractsDir, '/', name + '-contract-address.json'),
                JSON.stringify({[name]: contract.address}, undefined, 2)
            );
        }
        // файлик с интерфейсом
        // получаем артифакт (файлик contract_name.json) по имени смарт контракта
        const ContractArtifact = hre.artifacts.readArtifactSync(name);
        fs.writeFileSync(
            path.join(contractsDir, '/', name + '.json'), 
            JSON.stringify(ContractArtifact, null, 2)
        );
    })

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
