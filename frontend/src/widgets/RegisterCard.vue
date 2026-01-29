<script setup lang="ts">
import CardPanel from "@/components/CardPanel.vue";
import { router } from "@/config/router";
import { t } from "@/lang/i18n";
import { registerUser } from "@/services/apis";
import { useAppStateStore } from "@/stores/useAppStateStore";
import { sleep } from "@/tools/common";
import { reportErrorMsg } from "@/tools/validator";
import type { LayoutCard } from "@/types";
import {
  CheckCircleOutlined,
  LoadingOutlined,
  LockOutlined,
  UserOutlined
} from "@ant-design/icons-vue";
import { message } from "ant-design-vue";
import { onMounted, reactive, ref } from "vue";

const props = defineProps<{
  card?: LayoutCard;
}>();

const formData = reactive({
  username: "",
  password: "",
  confirmPassword: ""
});

const { execute: register } = registerUser();
const { updateUserInfo, isAdmin, state: appConfig } = useAppStateStore();

const registerStep = ref(0);

const handleRegister = async () => {
  if (!formData.username.trim() || !formData.password.trim()) {
    return message.error(t("TXT_CODE_c846074d"));
  }
  if (formData.password !== formData.confirmPassword) {
    return message.error(t("TXT_CODE_register_password_mismatch"));
  }
  if (formData.password.length < 9 || formData.password.length > 36) {
    return message.error(t("TXT_CODE_register_password_length"));
  }
  // Check password complexity: must contain lowercase, uppercase and number
  const passwordRegex = /(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])/;
  if (!passwordRegex.test(formData.password)) {
    return message.error(t("TXT_CODE_register_password_complexity"));
  }
  try {
    registerStep.value++;
    await sleep(600);
    await register({
      data: {
        username: formData.username,
        password: formData.password
      }
    });
    await sleep(600);
    await handleNext();
  } catch (error: any) {
    registerStep.value = 0;
    reportErrorMsg(error);
  }
};

const handleNext = async () => {
  try {
    await updateUserInfo();
    registerStep.value++;
    await sleep(1000);
    registerSuccess();
  } catch (error: any) {
    console.error(error);
    registerStep.value = 0;
    message.error(t("TXT_CODE_register_failed"));
  }
};

const registerSuccess = () => {
  registerStep.value++;
  if (isAdmin.value) {
    router.push({
      path: "/"
    });
  } else {
    router.push({ path: "/customer" });
  }
};

const goToLogin = () => {
  router.push({ path: "/login" });
};

onMounted(async () => {
  if (!appConfig.isInstall) {
    router.push({ path: "/install" });
  }
  if (!appConfig.settings.allowRegister) {
    message.warning(t("TXT_CODE_register_disabled"));
    router.push({ path: "/login" });
  }
});
</script>

<template>
  <div
    :class="{
      registering: registerStep === 1,
      registerDone: registerStep === 3,
      'w-100': true,
      'h-100': true
    }"
  >
    <CardPanel class="register-panel">
      <template #body>
        <div v-show="registerStep === 0" class="register-panel-body">
          <a-typography-title :level="3" class="mb-20 glitch-wrapper">
            <div
              class="glitch"
              :data-text="props.card?.title ? props.card?.title : t('TXT_CODE_register_title')"
            >
              {{ props.card?.title ? props.card?.title : t("TXT_CODE_register_title") }}
            </div>
          </a-typography-title>
          <a-typography-paragraph class="mb-20">
            {{ t("TXT_CODE_register_subtitle") }}
          </a-typography-paragraph>
          <div class="account-input-container">
            <form @submit.prevent>
              <a-input
                v-model:value="formData.username"
                class="account"
                size="large"
                name="mcsm-register-name-input"
                :placeholder="t('TXT_CODE_80a560a1')"
              >
                <template #suffix>
                  <UserOutlined style="color: rgba(0, 0, 0, 0.45)" />
                </template>
              </a-input>
              <a-input
                v-model:value="formData.password"
                class="mt-20 account"
                type="password"
                :placeholder="t('TXT_CODE_551b0348')"
                size="large"
                name="mcsm-register-pw-input"
              >
                <template #suffix>
                  <LockOutlined style="color: rgba(0, 0, 0, 0.45)" />
                </template>
              </a-input>
              <a-input
                v-model:value="formData.confirmPassword"
                class="mt-20 account"
                type="password"
                :placeholder="t('TXT_CODE_register_confirm_password')"
                size="large"
                name="mcsm-register-pw-confirm-input"
                @press-enter="handleRegister"
              >
                <template #suffix>
                  <LockOutlined style="color: rgba(0, 0, 0, 0.45)" />
                </template>
              </a-input>

              <div class="mt-12 password-hint">
                <a-typography-text type="secondary">
                  {{ t("TXT_CODE_register_password_hint") }}
                </a-typography-text>
              </div>

              <div class="mt-24 flex-between align-center">
                <div class="mcsmanager-link">
                  <a href="javascript:void(0)" @click="goToLogin">
                    {{ t("TXT_CODE_register_have_account") }}
                  </a>
                </div>
                <div class="justify-end" style="gap: 10px">
                  <a-button
                    size="large"
                    type="primary"
                    style="min-width: 95px"
                    @click="handleRegister"
                  >
                    {{ t("TXT_CODE_register_submit") }}
                  </a-button>
                </div>
              </div>
            </form>
          </div>
        </div>
        <div v-show="registerStep === 1" class="register-panel-body flex-center">
          <div style="text-align: center">
            <LoadingOutlined class="registering-icon" :style="{ fontSize: '62px', fontWeight: 800 }" />
          </div>
        </div>
        <div v-show="registerStep >= 2" class="register-panel-body flex-center">
          <div style="text-align: center">
            <CheckCircleOutlined
              class="register-success-icon"
              :style="{
                fontSize: '62px',
                color: 'var(--color-green-6)'
              }"
            />
          </div>
        </div>
      </template>
    </CardPanel>
  </div>
</template>

<style lang="scss">
.account-input-container {
  input:-webkit-autofill {
    -webkit-text-fill-color: var(--color-gray-8) !important;
    -webkit-box-shadow: 0 0 0px 1000px transparent inset !important;
    background-color: transparent !important;
    background-image: none;
    transition: background-color 99999s ease-in-out 0s;
  }
  input {
    background-color: transparent;
    caret-color: #fff;
  }
}
</style>

<style lang="scss" scoped>
.registering {
  .register-panel {
    transform: scale(0.94);
    border: 2px solid var(--color-blue-5);
    box-shadow: 0 0 20px rgba(28, 120, 207, 0.3);
  }
}
.register-panel {
  margin: 0 auto;
  transition: all 0.4s;
  width: 100%;
  background-color: var(--login-panel-bg);

  .register-panel-body {
    padding: 28px 24px;
    min-height: 380px;
  }
}

.password-hint {
  font-size: 12px;
}

.mcsmanager-link {
  font-size: var(--font-body);
  text-align: right;
  color: var(--color-gray-7);
  a {
    color: var(--color-blue-5) !important;
    text-decoration: underline;
  }
}
.registering-icon {
  animation: opacityAnimation 0.4s;
}
.register-success-icon {
  animation: scaleAnimation 0.4s;
}

@keyframes opacityAnimation {
  0% {
    opacity: 0;
  }
  100% {
    opacity: 1;
  }
}

@keyframes scaleAnimation {
  0% {
    transform: scale(0);
  }
  100% {
    transform: scale(1);
  }
}

.glitch-wrapper {
  position: relative;
  overflow: hidden;
}

.glitch {
  position: relative;
  font-weight: 600;
  animation: glitch-trigger 4s infinite;

  &::before,
  &::after {
    content: attr(data-text);
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: transparent;
    overflow: hidden;
    opacity: 0;
    pointer-events: none;
  }

  &::before {
    color: #ff0040;
    animation: glitch-anim-1 4s infinite;
  }

  &::after {
    color: #00ffff;
    animation: glitch-anim-2 4s infinite;
  }
}

@keyframes glitch-trigger {
  0%,
  96% {
    transform: translate(0);
  }
  97%,
  100% {
    transform: translate(-1px, 1px);
  }
}

@keyframes glitch-anim-1 {
  0%,
  96% {
    transform: translate(0);
    opacity: 0;
    clip-path: polygon(0 0, 100% 0, 100% 100%, 0 100%);
  }
  97% {
    transform: translate(-2px, -2px);
    opacity: 0.7;
    clip-path: polygon(0 0, 100% 0, 100% 35%, 0 35%);
  }
  98% {
    transform: translate(2px, 1px);
    opacity: 0.8;
    clip-path: polygon(0 35%, 100% 35%, 100% 70%, 0 70%);
  }
  99% {
    transform: translate(-1px, 2px);
    opacity: 0.9;
    clip-path: polygon(0 70%, 100% 70%, 100% 100%, 0 100%);
  }
  100% {
    transform: translate(0);
    opacity: 0;
    clip-path: polygon(0 0, 100% 0, 100% 100%, 0 100%);
  }
}

@keyframes glitch-anim-2 {
  0%,
  96% {
    transform: translate(0);
    opacity: 0;
    clip-path: polygon(0 0, 100% 0, 100% 100%, 0 100%);
  }
  97% {
    transform: translate(2px, 1px);
    opacity: 0.6;
    clip-path: polygon(0 0, 100% 0, 100% 25%, 0 25%);
  }
  98% {
    transform: translate(-2px, -1px);
    opacity: 0.7;
    clip-path: polygon(0 25%, 100% 25%, 100% 75%, 0 75%);
  }
  99% {
    transform: translate(1px, -2px);
    opacity: 0.8;
    clip-path: polygon(0 75%, 100% 75%, 100% 100%, 0 100%);
  }
  100% {
    transform: translate(0);
    opacity: 0;
    clip-path: polygon(0 0, 100% 0, 100% 100%, 0 100%);
  }
}
</style>
