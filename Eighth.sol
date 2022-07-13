// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Mercle tree
// Например есть 8 транзакций T1, T2, ..., T8
// Транзакции объединены в 1 блок
// Надо удостовериться, что блок не был подделан и все транзакции там действительно представлены
// Для каждой транзакции считается её хеш H1, H2, ..., H8 (каждый такой элемент транзакция+хеш называется "листком")
// T - не обязательно должно быть транзакцией (может быть просто какими-то данными, которые вместе хранятся)

// Далее берутся 1 и 2 хеш и продуцируем на их основе хеш H1-2
// Берем 3 и 4 хеш и продуцируем H3-4
/// ...
// H7-8

// Далее опять берем соседние 2 хеша и формируем H1-2-3-4 и H5-6-7-8
// И опять формируем хеш H1-2-3-4-5-6-7-8 = H-root (корневой хеш)

// Как удостовериться, что в блоке есть Т5?
// У нас есть хеш транзакции Н5
// Нужно заново пересчитать H-root

// 1 шаг: 
// Считаем H5-6 - для этого нам потребуется H6
// 2 шаг: 
// Считаем H5-6-7-8 для этого нам потребуется H7-8
// 3 шаг:
// Считаем H1-2-3-4-5-6-7-8 для этого нам потребуется H1-2-3-4
// 4 шаг
// Получаем H-root и сравниваем со значением, которое у нас появилось в блокчейне
// Если значения совпадают, значит 5-ая транзакция присутствует в блоке и не было модифицирована
// Получается нам нужно узнать только 3 хеша (H6, H7-8, H1-2-3-4) чтобы подтвердить наличие Т5

// Количество листьев в древе всегда 2^n


contract Tree {
// наши транзакции, на основе которых будет продуцировать хеши:

//       H1-2-3-4
//   H1-2        H3-4
// H1    H2    H3    H4
// TX1   TX2   TX3   TX4

    bytes32[] public hashes;
    // массив строк для хранения транзакций
    string[4] public transactions = [
        "TX1: Sherlock -> John",
        "TX2: John -> Sherlock",
        "TX3: John -> Mary",
        "TX4: Mary -> Sherlock"
    ];

    // функция возвращает массив байтов (длину наперед мы не знаем)
    function encode(string memory input) public pure returns(bytes memory) {
        // кодирует строку для функции keccak256
        return abi.encodePacked(input);
    }

    function makeHash(string memory input) public pure returns(bytes32) {
        // функция возвращает хеш с длиной 32 байта
        return keccak256(
            // значение должно передаваться в закодированном виде:
            encode(input)
        );
    }

    constructor() {
        // количество листьев
        uint count = transactions.length;

        for (uint i = 0; i < count; i++) {
            // создали H1, H2, H3, H4
            // hashes.push(makeHash(transactions[i]));
            hashes.push(keccak256(abi.encodePacked(transactions[i])));
        }

        // uint offset = 0;
        // while (count > 0) {
        //     for (uint i = 0; i < count - 1; i += 2) {
        //         // используем keccak256, а не makeHash так как makeHash принимает только строки, а encodePacked возвращает байты
        //         hashes.push(keccak256(
        //             abi.encodePacked(
        //                 hashes[offset + i], hashes[offset + i + 1]
        //             )
        //         ));
        //     }
        //     offset += count;
        //     count /= 2;
        // }

// на n элементов нужно сделать n+n-1 операций хеширования
// первые n операций делаем в цикле выше
// в цикле ниже нужно сделать n-1 операций
// но так как идем с шагом 2, в условии цикла пишем i <= count + 1
        for (uint i = 0; i <= count + 1; i += 2) {
            hashes.push(keccak256(
                abi.encodePacked(
                    hashes[i], hashes[i + 1]
                )
            ));
        }
    }

    // будет говорить всё впорядке с транзакцией или нет
    // index - индекс транзакции в блоке
    // root - корневой хеш
    // proof - массив с данными, которые нужны чтобы подтвердить транзакцию
    function verify(string memory transaction, uint index, bytes32 root, bytes32[] memory proof) public pure returns(bool) {
        bytes32 hash = makeHash(transaction);
        // реализуем цикл, который будет обходить массив proof
        for (uint i = 0; i < proof.length; i++) {
            bytes32 element = proof[i];
            // определяем четность
            // так как если элемент под четным индексом, мы будем брать элемент справа (+1). Если элемент нечетный, будем брать элемент слева (-1)
            if (i % 2 == 1) {
                hash = keccak256(abi.encodePacked(element, hash));
            } else {
                hash = keccak256(abi.encodePacked(hash, element));
            }
            // далее поднимаемся на следующий уровень древа
            // там в 2 раза меньше элементов
            index /= 2;
        }
        return root == hash;
    }

    // данные для проверки:
    // "TX3: John -> Mary"
    // 2
    // 0x09b224c621fb4ff030cb745cf19402c0a25ffb707b359ace8780aeeacb0ac988
    // для индекса 2 нужны хеши с индексами 3 и 4:
    // ["0x69a40d72d1258df801a7ae1e36dd586717a112334f8d9ca4664a339168874ef5","0x58e9a664a4c1e26694e09437cad198aebc6cd3c881ed49daea6e83e79b77fead"]

    // хеши:
    // 0: 0x42e81e4ee398c91795855f56994d566fcc0d0bd7777fe9d9ea1b9a518343918a
    // 1: 0xae9162f02511c27b7eb32b9756af10968925d048b8d3fca928d5712da1ebc5b8
    // 2: 0x67ad9362673b920a987d060e93230eac77a89b8f42f5ffdb9b4948e676f36349
    // 3: 0x69a40d72d1258df801a7ae1e36dd586717a112334f8d9ca4664a339168874ef5
    // 4: 0x58e9a664a4c1e26694e09437cad198aebc6cd3c881ed49daea6e83e79b77fead
    // 5: 0xdf0a693db97e6d4043455ce841471e0f5782813729e4c1334d086ef9c7342a8c
    // 6: 0x09b224c621fb4ff030cb745cf19402c0a25ffb707b359ace8780aeeacb0ac988
}
