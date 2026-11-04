<script lang="ts">

    const border_styling = "rounded-md border-solid border-2 border-gray-500";
    import type { Quote, SortableField } from "#lib/utils.ts";
    import { QUALIFIERS_QUOTE_IDS } from "#lib/utils.ts";
    import { untrack } from "svelte";

    let username: HTMLInputElement;
    let enteredUsername: string = $state("");

    let sortingCriteria: string = $state("Length");
    let sortingDirection: number = $state(0);
    const directionMapping = ["", "ASC", "DESC"];

    let quotesPromise: Promise<Quote[]> = $derived.by(async () => {
        if(enteredUsername.length === 0) return [];

        let quotes: Quote[] = await Promise.all(QUALIFIERS_QUOTE_IDS.map(async (quoteId) => {
            const response = await fetch(`https://api.typegg.io/v1/users/${enteredUsername}/quotes/${quoteId}`);
            const data = await response.json();

            return {
                id: quoteId,
                length: data.quote.length,
                difficulty: data.quote.difficulty,
                pp: data.bestRace.pp,
                wpm: data.bestRace.wpm,
                acc: data.bestRace.accuracy
            };
            
        }));

        return quotes;
    });
    let sortedQuotesPromise: Promise<Quote[]> = $derived.by(async () => {
        sortingCriteria; sortingDirection;

        return [...await quotesPromise].sort((q1, q2) => {
            if(sortingDirection === 0) return 0;
            let c: number = 0;

            const assign = (criteria: SortableField) => {
                c = sortingDirection === 1 ? q1[criteria] - q2[criteria] : q2[criteria] - q1[criteria];
            }

            
            if(sortingCriteria === "Length")
                assign("length");
            else if(sortingCriteria === "Stars")
                assign("difficulty");
            else if(sortingCriteria === "PP (wpm)")
                assign("pp");
            else if(sortingCriteria === "Accuracy (%)")
                assign("acc");

            return c;
        });

    });

    $effect(() => {

        username.addEventListener("keydown", (event) => {
            if(event.key !== "Enter") return;

            console.log("Name entered:", username.value);
            enteredUsername = username.value;
            sortingCriteria = "Length";
            sortingDirection = 0;
        });

    });

</script>

{#snippet quoteRow(quote: Quote, index: number)}
    <tr>
        <td class="border border-gray-500 p-3 text-center">{index+1}</td>
        <td class="border border-gray-500 p-3 break-all">{quote.id}</td>
        <td class="border border-gray-500 p-3 text-center">{quote.length}</td>
        <td class="border border-gray-500 p-3 text-center">{quote.difficulty.toFixed(2)}</td>
        <td class="border border-gray-500 p-3 text-center">{quote.pp} ({quote.wpm})</td>
        <td class="border border-gray-500 p-3 text-center">{(quote.acc * 100).toFixed(2)}%</td>
    </tr>
{/snippet}

{#snippet tableHeader(criteria: string)}
    <th class="hover:bg-zinc-600 border border-gray-500 p-3 w-[12%]" scope="col" {@attach (elem) => {
        elem.addEventListener("click", () => {
            if(criteria !== sortingCriteria) {
                sortingDirection = 0;
            }

            sortingCriteria = criteria;
            sortingDirection = (sortingDirection+1)%3;
        });
    }}>{criteria}{sortingCriteria === criteria && sortingDirection !== 0 ? ` (${directionMapping[sortingDirection]})` : null}</th>
{/snippet}


<div class="my-[10vh] mx-auto h-[80vh] w-[90vw] md:w-[50vw] {border_styling} p-5 flex flex-col">
    <div class="mx-[30%] flex flex-col gap-y-[20px]">
        <div class="flex flex-col gap-y-[10px]">
            <span class="text-center">Enter your username, then press enter.</span>
            <input class="p-2 border-gray-400 border-solid border-1 focus:outline-none" bind:this={username}>
        </div>
    </div>
    <div class="mx-[10%] mt-[20px] flex-1 overflow-y-auto overflow-x-hidden min-h-0">
        {#await sortedQuotesPromise}
            Loading quotes...
        {:then quotes}

            {#if quotes.length > 0}
                <table class="w-full border-collapse border border-gray-500 table-fixed">
                    <caption>
                        Clicking on some of the column headers will allow you to use them as sorting
                    </caption>
                    <thead>
                        <tr>
                            <th class="border border-gray-500 p-3 w-[12%]" scope="col">Position</th>
                            <th class="border border-gray-500 p-3 w-[28%]" scope="col">Quote ID</th>
                            {@render tableHeader("Length")}
                            {@render tableHeader("Stars")}
                            {@render tableHeader("PP (wpm)")}
                            {@render tableHeader("Accuracy (%)")}
                        </tr>
                    </thead>
                    <tbody>
                        {#each quotes as quote, index (quote.id)}
                            {@render quoteRow(quote, index)}
                        {/each}
                    </tbody>
                </table>
            {/if}

        {:catch err}
            Unable to load your performances at this time. Try again later.

            {err.message}
        {/await}
    </div>
        
</div>