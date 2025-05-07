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
		{@debug item, hassProp} <!-- Temporäres Svelte @debug für Live-Inspektion -->
		{(() => {
		  console.log("[Content.svelte] Rendering custom card:", item.card_tag);
		  console.log("[Content.svelte] item.card_config:", JSON.parse(JSON.stringify(item.card_config)));
		  console.log("[Content.svelte] hassProp.states relevant for power-flow-card-plus:", 
		    JSON.parse(JSON.stringify({
		      gridConsumption: hassProp.states && hassProp.states['sensor.stromzahler_gesamtverbrauch'],
		      gridProduction: hassProp.states && hassProp.states['sensor.stromzahler_einspeisung'],
		      homeConsumption: hassProp.states && hassProp.states['sensor.aktueller_stromverbrauch']
		    })));
		  console.log("[Content.svelte] Full hassProp.states available:", hassProp.states && Object.keys(hassProp.states).length);
		  console.log("[Content.svelte] Full hassProp object:", hassProp);
		  return ''; // Gibt einen leeren String zurück, damit Svelte einen gültigen Ausdruck hat
		})()}
		<svelte:element
			this={item.card_tag}
			{...item.card_config} 
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
