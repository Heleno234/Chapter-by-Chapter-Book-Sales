
import { describe, expect, it } from "vitest";

const accounts = simnet.getAccounts();
const address1 = accounts.get("wallet_1")!;
const address2 = accounts.get("wallet_2")!;

describe("chapter-by-book tests", () => {
  it("ensures simnet is well initialised", () => {
    expect(simnet.blockHeight).toBeDefined();
  });

  it("should get initial total books", () => {
    const { result } = simnet.callReadOnlyFn("chapter-by-book", "get-total-books", [], address1);
    expect(result).toBeUint(0);
  });

  it("should create a new book", () => {
    const { result } = simnet.callPublicFn(
      "chapter-by-book",
      "create-book",
      ["\"Test Book\"", "\"A test book description\"", "\"https://example.com/cover.jpg\"", "1000000"],
      address1
    );
    expect(result).toBeOk(1);
  });

  it("should get book details after creation", () => {
    simnet.callPublicFn(
      "chapter-by-book",
      "create-book",
      ["\"My Book\"", "\"Book description\"", "\"https://example.com/cover.jpg\"", "500000"],
      address1
    );
    
    const { result } = simnet.callReadOnlyFn("chapter-by-book", "get-book", ["1"], address1);
    expect(result).toBeSome();
  });

  it("should publish a chapter", () => {
    simnet.callPublicFn(
      "chapter-by-book",
      "create-book",
      ["\"Chapter Book\"", "\"Book with chapters\"", "\"https://example.com/cover.jpg\"", "750000"],
      address1
    );

    const { result } = simnet.callPublicFn(
      "chapter-by-book",
      "publish-chapter",
      ["1", "1", "\"First Chapter\"", "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef", "\"Chapter preview text\"", "2500"],
      address1
    );
    expect(result).toBeOk(true);
  });

  it("should purchase a chapter", () => {
    simnet.callPublicFn(
      "chapter-by-book",
      "create-book",
      ["\"Purchase Book\"", "\"Book for purchase test\"", "\"https://example.com/cover.jpg\"", "1000000"],
      address1
    );

    simnet.callPublicFn(
      "chapter-by-book",
      "publish-chapter",
      ["1", "1", "\"Chapter One\"", "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890", "\"First chapter preview\"", "3000"],
      address1
    );

    const { result } = simnet.callPublicFn(
      "chapter-by-book",
      "purchase-chapter",
      ["1", "1"],
      address2
    );
    expect(result).toBeOk(true);
  });
});
