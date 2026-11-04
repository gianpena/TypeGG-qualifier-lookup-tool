FROM oven/bun:latest
WORKDIR /app
EXPOSE 5173

COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

COPY . .
CMD ["bun", "run", "dev", "--", "--host", "0.0.0.0"]