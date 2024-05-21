#include "ExampleApp.h"

#include <directxtk/DDSTextureLoader.h> // 큐브맵 읽을 때 필요
#include <tuple>
#include <vector>

#include "GeometryGenerator.h"

namespace Gb {

using namespace std;
using namespace DirectX;

ExampleApp::ExampleApp() : AppBase() {}

bool ExampleApp::Initialize() {

    if (!AppBase::Initialize())
        return false;

    BuildFilters();

    return true;
}

void ExampleApp::Update(float dt) {

    static float time = 0.0f;

    m_filters.back()->m_pixelConstData.iTime = time;
    m_filters.back()->UpdateConstantBuffers(m_device, m_context);

    time += dt;
}

void ExampleApp::Render() {

    // 후처리 필터
    for (auto &f : m_filters) {
        f->Render(m_context);
    }
}

void ExampleApp::BuildFilters() {
    
    static ComPtr<ID3D11ShaderResourceView> textureResourceView;

    m_filters.clear();

    auto shaderToy =
        make_shared<ImageFilter>(m_device, m_context, L"Sampling", L"Space",
                                 m_screenWidth, m_screenHeight);

    shaderToy->SetShaderResources({textureResourceView});
    shaderToy->SetRenderTargets({m_renderTargetView});
    m_filters.push_back(shaderToy);
}

void ExampleApp::UpdateGUI() {    
}
}