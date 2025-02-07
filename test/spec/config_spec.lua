local stub = require("luassert.stub")

describe("config", function()
    local c = require("null-ls.config")

    local mock_source = {
        method = "mockMethod",
        filetypes = { "txt", "markdown" },
        generator = {
            fn = function()
                print("I am a generator")
            end,
        },
    }

    after_each(function()
        c.reset()
    end)

    describe("get", function()
        it("should get config", function()
            c.setup({ debounce = 500 })

            assert.equals(c.get().debounce, 500)
        end)
    end)

    describe("reset", function()
        it("should reset config to defaults", function()
            c.setup({ debounce = 500 })

            c.reset()

            assert.equals(c.get().debounce, 250)
        end)
    end)

    describe("register", function()
        it("should register single source", function()
            c.register(mock_source)

            local generators = c.generators()

            assert.equals(vim.tbl_count(generators), 1)
            assert.equals(vim.tbl_count(generators[mock_source.method]), 1)
            assert.equals(vim.tbl_count(c.get()._filetypes), 2)
        end)

        it("should register function source", function()
            c.register(function()
                return mock_source
            end)

            local generators = c.generators()

            assert.equals(vim.tbl_count(generators), 1)
            assert.equals(vim.tbl_count(generators[mock_source.method]), 1)
        end)

        it("should register additional generators for same method", function()
            c.register(mock_source)
            c.register(mock_source)

            local generators = c.generators()

            assert.equals(vim.tbl_count(generators), 1)
            assert.equals(vim.tbl_count(generators[mock_source.method]), 2)
            assert.equals(vim.tbl_count(c.get()._filetypes), 2)
        end)

        it("should register multiple sources from simple list", function()
            c.register({ mock_source, mock_source })

            local generators = c.generators()

            assert.equals(vim.tbl_count(generators), 1)
            assert.equals(vim.tbl_count(generators[mock_source.method]), 2)
            assert.equals(vim.tbl_count(c.get()._filetypes), 2)
        end)

        it("should register multiple sources with shared configuration", function()
            c.register({
                filetypes = { "txt" }, -- should take precedence over source filetypes
                sources = { mock_source, mock_source },
            })

            local generators = c.generators()

            assert.equals(vim.tbl_count(generators), 1)
            assert.equals(vim.tbl_count(generators[mock_source.method]), 2)
            assert.equals(vim.tbl_count(c.get()._filetypes), 1)
        end)
    end)

    describe("reset_sources", function()
        it("should reset sources only", function()
            c.setup({ debounce = 500, sources = { mock_source } })

            c.reset_sources()

            assert.equals(vim.tbl_count(c.generators()), 0)
            assert.equals(c.get().debounce, 500)
        end)
    end)

    describe("generators", function()
        before_each(function()
            c.register(mock_source)
        end)

        it("should get generators matching method", function()
            local generators = c.generators(mock_source.method)

            assert.equals(vim.tbl_count(generators), 1)
        end)

        it("should get all generators", function()
            local all_generators = c.generators()

            assert.equals(vim.tbl_count(all_generators), 1)
            assert.equals(vim.tbl_count(all_generators[mock_source.method]), 1)
        end)
    end)

    describe("setup", function()
        it("should set simple config value", function()
            local debounce = 999

            c.setup({ debounce = debounce })

            assert.equals(c.get().debounce, debounce)
        end)

        it("should only setup config once", function()
            c.setup({ debounce = 999 })

            c.setup({ debounce = 1 })

            assert.equals(c.get().debounce, 999)
        end)

        it("should throw if simple config type does not match", function()
            local debounce = "999"

            local ok, err = pcall(c.setup, { debounce = debounce })

            assert.equals(ok, false)
            assert.matches("expected number", err)
        end)

        it("should set override config value", function()
            local on_attach = stub.new()
            local _on_attach = function()
                on_attach()
            end

            c.setup({ on_attach = _on_attach })
            c.get().on_attach()

            assert.stub(on_attach).was_called()
        end)

        it("should throw if override config type does not match", function()
            local on_attach = { "my function" }

            local ok, err = pcall(c.setup, { on_attach = on_attach })

            assert.equals(ok, false)
            assert.matches("expected function, nil", err)
        end)

        it("should throw if config value is private", function()
            local _names = { "my-integration" }

            local ok, err = pcall(c.setup, { _names = _names })

            assert.equals(ok, false)
            assert.matches("expected nil", err)
        end)

        it("should register sources", function()
            c.setup({ sources = { mock_source } })

            local generators = c.generators()

            assert.equals(vim.tbl_count(generators), 1)
            assert.equals(vim.tbl_count(generators[mock_source.method]), 1)
            assert.equals(vim.tbl_count(c.get()._filetypes), 2)
        end)
    end)
end)
