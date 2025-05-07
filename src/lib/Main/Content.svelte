<script lang="ts">
	import { SHADOW_ITEM_MARKER_PROPERTY_NAME } from 'svelte-dnd-action';
	import Button from '$lib/Main/Button.svelte';
	import ConditionalMedia from '$lib/Main/ConditionalMedia.svelte';
	import PictureElements from '$lib/Main/PictureElements.svelte';
	import Camera from '$lib/Main/Camera.svelte';
	import Configure from '$lib/Main/Configure.svelte';
	import Empty from '$lib/Main/Empty.svelte';
	import Template from '$lib/Main/Template.svelte';
	import {
		config as hassConfig,
		states as hassStates,
		connection,
		lang,
		services as hassServices
	} from '$lib/Stores';
	import { tick } from 'svelte';

	export let item: any;
	export let sectionName: string | undefined = undefined;

	const large = ['conditional_media', 'picture_elements', 'camera'];

	// Definiere das hassProp Objekt hier reaktiv
	$: hassProp = {
		config: $hassConfig,
		states: $hassStates,
		connection: $connection,
		services: $hassServices,
		user: $connection?.user,
		callService: ($connection && typeof $connection.callService === 'function') 
					 ? $connection.callService.bind($connection) 
					 : undefined,
		localize: $lang,
		provideHass: (element: any) => {
			if (element) element.hass = hassProp;
		}
	};

	let cardElement: HTMLElement & { setConfig?: (config: any) => void, config?: any };

	// Reaktiver Block, der ausgeführt wird, wenn sich relevante Props ändern
	$: if (item?.type === 'custom_card' && item?.card_tag && cardElement && item?.card_config) {
		// Erstelle eine tiefe Kopie von item.card_config, um Seiteneffekte zu vermeiden
		const configCopy = JSON.parse(JSON.stringify(item.card_config));
		tick().then(() => { 
			if (cardElement && typeof cardElement.setConfig === 'function') {
				console.log("[Content.svelte] Calling setConfig on custom card with:", configCopy);
				try {
					cardElement.setConfig(configCopy);
				} catch (e) {
					console.error("[Content.svelte] Error calling setConfig on custom card:", e, "Element:", cardElement, "Config:", configCopy);
				}
			} else if (cardElement) {
				// Fallback: Wenn setConfig nicht existiert, versuche config direkt zu setzen (obwohl dies oft durch Props passiert)
				console.warn("[Content.svelte] Custom card does not have a setConfig method. Attempting to set .config property. Current element.config:", cardElement.config);
				try {
					cardElement.config = configCopy;
				} catch (e) {
					console.error("[Content.svelte] Error setting .config property on custom card:", e, "Element:", cardElement, "Config:", configCopy);
				}
			}
		});
	}

</script>

{#if item?.[SHADOW_ITEM_MARKER_PROPERTY_NAME] && large.includes(item?.type)}
	<div class="shadow"></div>
{/if}

{#if item?.type === 'configure'}
	<Configure sel={item} />
{:else if item?.type === 'button'}
	<Button sel={item} {sectionName} />
{:else if item?.type === 'conditional_media'}
	<ConditionalMedia sel={item} />
{:else if item?.type === 'picture_elements'}
	<PictureElements sel={item} />
{:else if item?.type === 'camera'}
	<Camera sel={item} responsive={false} muted={true} controls={false} />
{:else if item?.type === 'empty'}
	<Empty sel={item} />

	<!-- NEU: Custom Card Rendering -->
{:else if item?.type === 'custom_card' && item?.card_tag}
	<div class="custom-card-wrapper">
		{(() => {
		  // Die Debug-Logs können hier bleiben oder reduziert werden, wenn der Fehler gefunden ist
		  // console.log("[Content.svelte] Rendering custom card:", item.card_tag);
		  // let configToLog = {};
		  // try { configToLog = JSON.parse(JSON.stringify(item.card_config)); } catch(e) { configToLog = { error: "Could not stringify card_config" }; }
		  // console.log("[Content.svelte] item.card_config to be passed:", configToLog);
		  return ''; 
		})()}
		<svelte:element
			this={item.card_tag}
			bind:this={cardElement} 
			hass={hassProp}
		></svelte:element>
	</div>
{:else if item?.type === 'custom_card' && !item?.card_tag}
	<div class="custom-card-error">
		<p>Custom Card Error: card_tag is not defined.</p>
		<p>Please configure the card and set a valid tag name.</p>
	</div>

	<!-- NEU: Template Card Rendering -->
{:else if item?.type === 'template'}
	<Template sel={item} />

{:else}
	<!-- if types are changed internally, don't break ui -->
	<Configure sel={{ id: item?.id }} />
{/if}

<style>
	.shadow {
		position: absolute;
		top: 0;
		left: 0;
		right: 0;
		bottom: 0;
		visibility: visible;
		background: rgba(0, 0, 0, 0.125);
		margin: 0;
		border-radius: 0.65rem;
	}

	.custom-card-wrapper {
		height: 100%;
		display: flex; 
		align-items: stretch; 
	}

	.custom-card-wrapper > :global(*) {
    width: 100%; 
  }

	.custom-card-error {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		height: 100%;
		padding: 1rem;
		text-align: center;
		background-color: rgba(255, 0, 0, 0.1);
		border: 1px dashed red;
		border-radius: 0.65rem;
		color: red;
	}
</style>
