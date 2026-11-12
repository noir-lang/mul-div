# Changelog

## [0.1.0-rc.2](https://github.com/noir-lang/mul-div/compare/v0.1.0-rc.1...v0.1.0-rc.2) (2026-11-12)


### Bug Fixes

* Name the AsPrimitive&lt;Field&gt; conversion in mul_div_rem ([#23](https://github.com/noir-lang/mul-div/issues/23)) ([fddd97e](https://github.com/noir-lang/mul-div/commit/fddd97e2e56d0644f48cdac79b39f5e1b1cf51b5))

## 0.1.0-rc.1 (2026-11-12)


### ⚠ BREAKING CHANGES

* drop the U256 impl and the bigint dependency ([#18](https://github.com/noir-lang/mul-div/issues/18))
* make the MulDiv trait the only public API ([#9](https://github.com/noir-lang/mul-div/issues/9))

### Features

* Drop the U256 impl and the bigint dependency ([#18](https://github.com/noir-lang/mul-div/issues/18)) ([c0ca359](https://github.com/noir-lang/mul-div/commit/c0ca35969c0ed8f33b68ff775dd20920a2d1d808))
* Implement MulDiv for u8, u16, u32 and u64 ([#12](https://github.com/noir-lang/mul-div/issues/12)) ([78c1eb6](https://github.com/noir-lang/mul-div/commit/78c1eb6241968ce2cfefa0b663fd854f3d1d495f))
* Make the MulDiv trait the only public API ([#9](https://github.com/noir-lang/mul-div/issues/9)) ([a459fae](https://github.com/noir-lang/mul-div/commit/a459fae98db3066096d4444e434638457e6ca50f))
* Verify u128 mul_div without bigint ([#17](https://github.com/noir-lang/mul-div/issues/17)) ([7865922](https://github.com/noir-lang/mul-div/commit/78659225cdb8fbf29da4fa512d834d774fc025c1))
