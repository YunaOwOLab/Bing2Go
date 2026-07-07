FROM node:20-slim AS base

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN corepack enable \
    && corepack prepare pnpm@10 --activate

WORKDIR /app

COPY . /app

# =========================
# 安裝正式環境依賴階段
# =========================

FROM base AS prod-deps

RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --prod --frozen-lockfile

# =========================
# 建置階段
# =========================

FROM base AS build

RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile
RUN pnpm run build

# =========================
# 最終執行階段
# =========================

FROM base AS runtime

COPY --from=prod-deps /app/node_modules /app/node_modules
COPY --from=build /app/.output /app/.output

CMD [ "pnpm", "start" ]
