<script lang="ts">
	import { connection, config, templates, lang, editMode } from '$lib/Stores'; // editMode hinzugefügt für Klick-Handler
	import { marked } from 'marked';
	import { onDestroy } from 'svelte';
	import type { TemplateItem } from '$lib/Types'; // Wir könnten einen allgemeineren Typ verwenden, falls nötig

	export let sel: TemplateItem | undefined = undefined; // Enthält id und template String
	export let demo = false; // Für Vorschauzwecke

	let unsubscribe: () => void;
	let id = sel?.id;
	let error = false;

	$: template = sel?.template;

	// Reagiert auf Änderungen im Template-String oder wenn die Verbindung bereit ist
	$: if ($config?.state === 'RUNNING' && template && id && !demo) {
		renderTemplate(template);
	}

	/**
	 * Renders template by id to `$templates` store
	 */
	async function renderTemplate(data: string) {
		if (!$connection || !id) return;

		const handleResponse = (response: { result?: string }) => {
			if (response?.result && id) {
				// Sanitize HTML slightly before parsing with marked, to prevent XSS if templates are not trusted.
				// marked.parse itself also has sanitization options if needed.
				$templates[id] = marked.parse(response.result) as any;
				error = false;
			}
		};

		const handleError = (err: any) => {
			if (err?.code === 'template_error' && id) {
				console.warn('render_template error for item:', id, err);
				$templates[id] = `<span class="error-message">Template Error: ${err.message}</span>`;
				error = true;
			}
		};

		try {
			// Ensure we don't create duplicate subscriptions if template re-renders
			unsubscribe?.(); 
			unsubscribe = await $connection.subscribeMessage(handleResponse, {
				type: 'render_template',
				template: data
			});
		} catch (e) {
			handleError(e);
		}
	}

    // Klick-Handler von Sidebar/Template.svelte übernommen, um Edit-Mode-Verhalten zu steuern
    function handleEvent(event: Event) {
		if (event?.type === 'click' && $editMode) {
			event.preventDefault(); 
		} else if (event?.type === 'pointerenter') {
			const targetElement = event.target as HTMLElement;
			const links = targetElement.querySelectorAll('a');
			links.forEach((anchor: HTMLAnchorElement) => {
				anchor.style.cursor = !$editMode ? 'pointer' : 'unset';
			});
		} else if ((event?.type === 'pointerdown' && $editMode) || event?.type === 'pointerup') {
			const targetElement = event.target as HTMLElement;
			const lists = targetElement.querySelectorAll('li');
			lists?.forEach((list) => {
				list.style.pointerEvents = event?.type === 'pointerdown' && $editMode ? 'none' : 'unset';
			});
		}
	}

	/**
	 * Websocket unsubscribe 'render_template'
	 */
	onDestroy(() => {
		unsubscribe?.();
        // Optional: Template aus dem Store entfernen, wenn die Komponente zerstört wird?
        // if (id && $templates?.[id]) {
        // delete $templates[id];
        // }
	});
</script>

<div 
    class="template-card-content"
    on:click={handleEvent}
    on:pointerenter={handleEvent}
    on:keydown
	role="button"
	tabindex="0"
>
	{#if demo}
		<div class="template-demo-text">
			<span>&#123;&#123;</span> template <span>&#125;&#125;</span>
		</div>
	{:else if id && $templates?.[id]}
		<!-- svelte-ignore security-DisableHtmlSanitization -->
		<span class:error={error}>{@html $templates?.[id]}</span>
	{:else if template && !error}
        <span class="loading-text">{$lang('loading') || 'Loading...'}</span>
	{:else if error && id && $templates?.[id]}
        <!-- Fehler wird bereits im $templates[id] als HTML gerendert -->
        <!-- svelte-ignore security-DisableHtmlSanitization -->
        <span>{@html $templates?.[id]}</span>
    {:else if template && error}
        <span class="error-message">{$lang('template_error_preview') || 'Error rendering template.'}</span>
	{:else}
		<span class="no-template-text">{$lang('template_not_configured') || 'Template not configured'}</span>
	{/if}
</div>

<style>
	.template-card-content {
		width: 100%;
		height: 100%;
		padding: 1rem; /* Allgemeines Padding für Dashboard-Karten */
		word-wrap: break-word;
		text-shadow: 0px 0px 5px rgba(0, 0, 0, 0.1);
		display: flex; /* Hilft bei der Zentrierung von Text, falls kein Inhalt da ist */
		align-items: center;
		justify-content: center;
		overflow: auto; /* Falls der Inhalt größer als die Karte ist */
	}

    .template-card-content > span {
        width: 100%; /* Span soll die volle Breite einnehmen für Text-Alignment */
        text-align: left; /* Standard Textausrichtung */
    }

    .template-card-content :global(img) {
        max-width: 100%;
        height: auto;
        border-radius: 0.3rem;
    }

	.error-message,
    .loading-text,
    .no-template-text,
    .template-demo-text {
        text-align: center; /* Zentriert den Text für diese speziellen Zustände */
        width: 100%;
    }

	.error-message {
		color: var(--hf-error-color, red); /* Theming-Variable oder Fallback */
	}

    .loading-text {
        color: var(--hf-text-secondary-color, #aaa); /* Theming oder Fallback */
    }

    .no-template-text {
        color: var(--hf-text-disabled-color, #888); /* Theming oder Fallback */
    }

	.template-demo-text {
		color: #e06c75; /* Aus Sidebar/Template.svelte übernommen */
		font-family: monospace;
		font-size: 1.15rem;
		text-align: center;
	}

	.template-demo-text > span {
		color: #e5c07b; /* Aus Sidebar/Template.svelte übernommen */
	}
</style> 