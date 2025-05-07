<script lang="ts">
	import { dashboard, record, lang, ripple, autocompleteList, editMode } from '$lib/Stores';
	import { closeModal, openModal } from 'svelte-modals';
	import Modal from '$lib/Modal/Index.svelte';
	import ConfigButtons from '$lib/Modal/ConfigButtons.svelte';
	import CodeEditor from '$lib/Components/CodeEditor.svelte';
	import { onMount } from 'svelte';
	import Ripple from 'svelte-ripple';

	export let isOpen: boolean;
	export let sel: any; // Das aktuell ausgewählte Element/Objekt

	let cardTagName = sel?.card_tag || ''; // Initialwert aus sel.card_tag oder leer
	let cardConfigString = sel?.card_config ? JSON.stringify(sel.card_config, null, 2) : '{}\n';
	let parseError = '';
	let editorComponent: CodeEditor; // Für den Fokus
	let inputElement: HTMLInputElement;

	onMount(() => {
		console.log('CustomCardConfig - onMount - sel:', JSON.parse(JSON.stringify(sel)));
		console.log('CustomCardConfig - onMount - $editMode:', $editMode);
		if (isOpen && inputElement && !editorComponent) {
			setTimeout(() => inputElement.focus(), 0);
		}
	});

	function saveAndClose() {
		parseError = '';
		if (sel) {
			sel.card_tag = cardTagName.trim();
			if (!sel.card_tag) {
				parseError = 'Card Tag Name cannot be empty.';
				return;
			}
			try {
				sel.card_config = JSON.parse(cardConfigString);
			} catch (e: any) {
				parseError = `Invalid JSON: ${e.message}`;
				return; 
			}
			$dashboard = $dashboard;
			$record();
		}
		closeModal();
	}

	function removeThisItem() {
		if (!sel) return;
		closeModal();

		$dashboard.views = $dashboard.views.map((view:any) => ({
			...view,
			sections: view.sections?.map((section:any) => ({
				...section,
				sections:
					section.type === 'horizontal-stack' && section.sections
						? section.sections.map((nestedSection:any) => ({
								...nestedSection,
								items: nestedSection.items?.filter((item:any) => item.id !== sel.id)
							}))
						: section.sections,
				items:
					section.type !== 'horizontal-stack'
						? section.items?.filter((item:any) => item.id !== sel.id)
						: section.items
			}))
		}));
		$record();
	}

	function handleKeydown(event: KeyboardEvent) {
		if (event.key === 'Enter' && (document.activeElement === inputElement || document.activeElement?.tagName !== 'TEXTAREA')) {
			event.preventDefault();
			saveAndClose();
		}
		if (event.key === 'Escape') {
			event.stopPropagation();
			closeModal();
		}
	}
</script>

<svelte:window on:keydown|capture={handleKeydown} />

{#if isOpen}
	<Modal size="medium">
		<h1 slot="title">{$lang('configure_custom_card') || 'Configure Custom Card'}</h1>

		<div class="form-container">
			<label for="card-tag-name">{$lang('custom_card_tag_name') || 'Card Tag Name'}</label>
			<input
				id="card-tag-name"
				type="text"
				placeholder="example: power-flow-card-plus"
				bind:value={cardTagName}
				bind:this={inputElement} 
			/>

			<label for="card-config-json">{$lang('custom_card_config_json') || 'Card Configuration (JSON)'}</label>
			<CodeEditor
				bind:this={editorComponent}
				bind:value={cardConfigString}
				type="json"
				placeholder={`{ 
  "type": "custom:power-flow-card-plus",
  "entities": {
    "solar": "sensor.solar_power"
  }
}`}
				autocompleteList={$autocompleteList}
			/>
			{#if parseError}
				<p class="error-message">{parseError}</p>
			{/if}
		</div>

		<div class="config-buttons-container">
			<div class="align-left">
				{#if $editMode && sel?.id}
					<button class="remove action" on:click={removeThisItem} use:Ripple={{...$ripple, color: 'rgba(0,0,0,0.35)'}}>
						{$lang('remove') || 'Remove'}
					</button>
				{/if}
			</div>
			<button class="done action" on:click={saveAndClose} use:Ripple={$ripple}>
				{$lang('done') || 'Done'}
			</button>
		</div>
	</Modal>
{/if}

<style>
	.form-container {
		display: flex;
		flex-direction: column;
		gap: 0.75rem; /* Etwas mehr Platz */
		padding: 1rem 0;
	}

	label {
		font-size: 0.9rem;
		color: var(--hf-text-secondary-color, #ccc); /* Fallback-Farbe */
		margin-bottom: 0.25rem;
	}

	input[type="text"] {
		width: 100%;
		padding: 0.5rem;
		border-radius: 0.3rem;
		border: 1px solid var(--hf-border-color, #555); /* Fallback-Farbe */
		background-color: var(--hf-input-background, #333); /* Fallback-Farbe */
		color: var(--hf-text-color, #fff); /* Fallback-Farbe */
		font-size: 1rem;
		margin-bottom: 0.5rem; /* Platz unter dem Tag-Namen-Input */
	}

	input[type="text"]:focus {
		outline: none;
		border-color: var(--hf-accent-color, #ffa500); /* Fallback-Farbe Orange für Akzent */
		box-shadow: 0 0 0 2px var(--hf-accent-color-faded, rgba(255,165,0,0.5)); /* Fallback-Farbe */
	}

	.error-message {
		color: var(--hf-error-color, red);
		font-size: 0.85rem;
		margin-top: 0.5rem;
	}

	/* Style für CodeEditor Höhe anpassen, falls nötig */
	:global(.cm-editor) { 
		min-height: 150px; /* Mindesthöhe für JSON-Eingabe */
		border: 1px solid var(--hf-border-color, #555);
		border-radius: 0.3rem;
	}

	.config-buttons-container {
		display: flex;
		justify-content: space-between;
		margin-top: 2.37rem;
	}

	.align-left {
		display: flex;
		gap: 0.8rem;
	}

	.action {
		padding: 0.5em 1em;
		border-radius: 0.3em;
		border: 1px solid transparent;
		cursor: pointer;
		font-weight: 500;
	}

	.remove.action {
		background-color: var(--hf-error-color, #c83737);
		color: white;
	}

	.done.action {
		background-color: var(--hf-accent-color, #03a9f4);
		color: white;
	}
</style> 