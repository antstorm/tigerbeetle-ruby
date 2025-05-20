package main

import (
     "fmt"
     "log"
     "os"
		 "time"
		 "strconv"
		 "math"

     tb "github.com/tigerbeetle/tigerbeetle-go"
     . "github.com/tigerbeetle/tigerbeetle-go/pkg/types"
)

const ledger = 888
const code = 1

func readEnv(key string, value int) int {
	value, err := strconv.Atoi(os.Getenv(key))
	if err != nil { return value }

	return value
}

func min(a int, b int) int {
	if a < b { return a }
	
	return b
}

func createAccounts(client tb.Client) (Uint128, Uint128) {
	account_1 := Account{ ID: ID(), Ledger: ledger, Code: code }
	account_2 := Account{ ID: ID(), Ledger: ledger, Code: code }

	_, err := client.CreateAccounts([]Account{account_1, account_2})
	if err != nil {
		log.Println("Unable to create accounts: %s", err)
	}
	
	return account_1.ID, account_2.ID
}

func createTransfer(debit_account_id Uint128, credit_account_id Uint128) Transfer {
	return Transfer{
		ID: ID(),
		DebitAccountID: debit_account_id,
		CreditAccountID: credit_account_id,
		Amount: ToUint128(10),
		Ledger: ledger,
		Code: code,
	}
}

func runTest(client tb.Client, total int, batch_size int, from Uint128, to Uint128) (int64, int64) {
	minT := int64(math.Inf(1))
	maxT := int64(0)

	for total > 0 {
		batch_size_adj := min(total, batch_size)
		transfers := make([]Transfer, batch_size_adj)
		
		for i := 0; i < batch_size_adj; i++ {
			transfers = append(transfers, createTransfer(from, to))
		}
		
		start := time.Now()
		_, err := client.CreateTransfers(transfers)
		if err != nil {
			log.Println("Unable to create transfers: %s", err)
		}
		elapsed := time.Since(start).Milliseconds()
		
		total -= batch_size

		if elapsed > maxT { maxT = elapsed }
		if elapsed < minT { minT = elapsed }
	}

	return minT, maxT
}

func main() {
    fmt.Println("Import ok!")

		tbAddress := os.Getenv("TB_ADDRESS")
		if len(tbAddress) == 0 {
				tbAddress = "3000"
		}
		client, err := tb.NewClient(ToUint128(0), []string{tbAddress})
		if err != nil {
				log.Printf("Error creating client: %s", err)
				return
		}
		defer client.Close()

		from, to := createAccounts(client)

		n := readEnv("N", 10_000)
		b := readEnv("B", 1_000)

		start := time.Now()	
		min, max := runTest(client, n, b, from, to)
		elapsed := time.Since(start).Milliseconds()
		
		fmt.Printf("Total time: %d ms\n", elapsed)
		fmt.Printf("Avg: %f ms\n", float64(elapsed) / float64(n))
		fmt.Printf("Min batch time: %d ms\n", min)
		fmt.Printf("Max batch time: %d ms\n", max)
}
