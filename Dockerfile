FROM oven/bun:latest
WORKDIR /app
EXPOSE 3000

COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

COPY . .
CMD ["bun", "run", "dev"]