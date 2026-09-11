<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Cookies from 'js-cookie';

const { t } = useI18n();

// SSO com o Portal de Relatórios (app externo, embedado via iframe):
// 1. o portal carrega em /sso e avisa "tô pronto" (PORTAL_READY)
// 2. lemos os headers de sessão que o PRÓPRIO Chatwoot já usa em toda
//    chamada de API dele (access-token/client/uid, salvos no cookie
//    cw_d_session_info no login) — mesmo padrão já usado em
//    useWhatsappCallSession.js
// 3. mandamos esses headers pro iframe por postMessage (nunca pela URL)
// 4. o portal troca isso por uma sessão dele — sem pedir email/senha de novo
const portalURL = window.chatwootConfig?.reportsPortalURL || '';
const portalOrigin = computed(() => {
  try {
    return portalURL ? new URL(portalURL).origin : '';
  } catch {
    return '';
  }
});

const iframeRef = ref(null);

const getDeviseAuthHeaders = () => {
  try {
    const raw = Cookies.get('cw_d_session_info');
    if (!raw) return null;
    const session = JSON.parse(raw);
    const accessToken = session['access-token'];
    const { client, uid } = session;
    if (!accessToken || !client || !uid) return null;
    return { accessToken, client, uid };
  } catch {
    return null;
  }
};

const handleMessage = event => {
  if (!portalOrigin.value || event.origin !== portalOrigin.value) return;
  if (event.data?.type !== 'PORTAL_READY') return;

  const payload = getDeviseAuthHeaders();
  if (!payload) return;

  iframeRef.value?.contentWindow?.postMessage(
    { type: 'CW_AUTH', payload },
    portalOrigin.value
  );
};

onMounted(() => window.addEventListener('message', handleMessage));
onBeforeUnmount(() => window.removeEventListener('message', handleMessage));
</script>

<template>
  <div class="w-full h-full bg-n-surface-1">
    <iframe
      v-if="portalURL"
      ref="iframeRef"
      :src="`${portalURL}/sso`"
      :title="t('REPORT.PORTAL.IFRAME_TITLE')"
      class="w-full h-full border-0"
    />
    <div
      v-else
      class="flex items-center justify-center w-full h-full text-sm text-n-slate-11"
    >
      {{ t('REPORT.PORTAL.NOT_CONFIGURED') }}
    </div>
  </div>
</template>
