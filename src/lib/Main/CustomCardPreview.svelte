<script lang="ts">
	import Icon from '@iconify/svelte';
	import { lang } from '$lib/Stores';
	export let sel: any; // Sel wird hier nicht wirklich verwendet, aber für Konsistenz mit anderen Previews
</script>

<div class="preview-container">
	<Icon icon="mdi:puzzle-outline" height="48px" />
	<p>{$lang('custom_card') || 'Custom Card'}</p>
</div>

<style>
	.preview-container {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		height: 100%;
		text-align: center;
		color: var(--hf-text-color, #fff); /* Fallback-Farbe */
	}
	p {
		margin-top: 0.5rem;
		font-size: 0.9rem;
	}
</style> 